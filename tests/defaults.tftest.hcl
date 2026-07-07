# Plan-time tests for the module. The azurerm provider is mocked, so no credentials, no
# features block, and no cloud calls are needed:
#   terraform init -backend=false && terraform test
#
# The vnet data sources are overridden per run: the derivation math needs real CIDR shapes,
# which the mock would otherwise invent.

mock_provider "azurerm" {}

variables {
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-rdns-01"
  tags              = { Environment = "tst" }

  virtual_network_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-rdns-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-001",
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-rdns-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-002",
  ]
}

run "dedupes_zones_and_meshes_links" {
  command = plan

  # Both vnets share the same /24, so one zone derives and both vnets link to it.
  override_data {
    target = data.azurerm_virtual_network.this
    values = {
      address_space = ["10.111.0.0/24"]
    }
  }

  assert {
    condition     = length(azurerm_private_dns_zone.this) == 1
    error_message = "Identical address spaces should dedupe into one zone."
  }

  assert {
    condition     = contains(keys(azurerm_private_dns_zone.this), "0.111.10.in-addr.arpa")
    error_message = "A /24 should derive its exact reverse zone."
  }

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.this) == 2
    error_message = "Every vnet should link to every derived zone."
  }

  assert {
    condition     = alltrue([for l in values(azurerm_private_dns_zone_virtual_network_link.this) : l.registration_enabled == false])
    error_message = "Auto-registration must stay off on reverse zone links."
  }
}

run "a_non_octet_cidr_lands_in_its_containing_zone" {
  command = plan

  variables {
    virtual_network_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-rdns-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-001",
    ]
  }

  override_data {
    target = data.azurerm_virtual_network.this
    values = {
      address_space = ["10.112.0.0/22"]
    }
  }

  expect_failures = [check.wide_containing_zones_are_visible]

  assert {
    condition     = contains(keys(azurerm_private_dns_zone.this), "112.10.in-addr.arpa")
    error_message = "A /22 should land in its containing /16 zone."
  }
}

run "a_wide_cidr_clamps_to_its_slash_eight" {
  command = plan

  variables {
    virtual_network_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-rdns-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-001",
    ]
  }

  override_data {
    target = data.azurerm_virtual_network.this
    values = {
      address_space = ["10.0.0.0/7"]
    }
  }

  expect_failures = [check.wide_containing_zones_are_visible]

  assert {
    condition     = contains(keys(azurerm_private_dns_zone.this), "10.in-addr.arpa")
    error_message = "Anything wider than /8 should clamp to the /8 of its network address."
  }
}

run "rejects_a_non_vnet_id" {
  command = plan

  variables {
    virtual_network_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/notavnet",
    ]
  }

  expect_failures = [var.virtual_network_ids]
}

run "rejects_an_empty_list" {
  command = plan

  variables {
    virtual_network_ids = []
  }

  expect_failures = [var.virtual_network_ids]
}
