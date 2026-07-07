locals {
  rg_name = provider::azurerm::parse_resource_id(var.resource_group_id)["resource_group_name"]

  # Parse each vnet id into its name and resource group for the data source reads. Keyed by the
  # full id so identically named vnets in different groups cannot collide.
  vnets = {
    for id in var.virtual_network_ids : id => {
      name    = provider::azurerm::parse_resource_id(id)["resource_name"]
      rg_name = provider::azurerm::parse_resource_id(id)["resource_group_name"]
    }
  }
}

data "azurerm_virtual_network" "this" {
  for_each = local.vnets

  resource_group_name = each.value.rg_name

  name = each.value.name
}

locals {
  # The smallest octet-boundary zone CONTAINING each CIDR: floor(prefix / 8) reversed network
  # octets suffixed with in-addr.arpa, clamped to at least one octet (10.70.0.0/24 gives
  # 0.70.10.in-addr.arpa, a /22 lands in its containing /16 zone, anything wider than /8 lands
  # in the /8 of its network address). Because the vnets already exist, the derived names are
  # known at plan time and safe as for_each keys.
  zones_per_vnet = {
    for id, v in data.azurerm_virtual_network.this : id => toset([
      for c in v.address_space :
      "${join(".", reverse(slice(split(".", split("/", c)[0]), 0, max(1, floor(tonumber(split("/", c)[1]) / 8)))))}.in-addr.arpa"
    ])
  }

  reverse_zones = toset(flatten([for id, zones in local.zones_per_vnet : tolist(zones)]))
}

resource "azurerm_private_dns_zone" "this" {
  for_each = local.reverse_zones

  resource_group_name = local.rg_name
  tags                = var.tags

  name = each.value
}

# Every vnet links to every derived zone, so reverse lookups resolve estate-wide, not just for
# addresses in the vnet's own ranges. Auto-registration stays off: Azure only auto-registers
# forward records, and a vnet's single registration-enabled link belongs to its forward zone.
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = {
    for pair in setproduct(local.reverse_zones, var.virtual_network_ids) :
    "${pair[0]}|${local.vnets[pair[1]].name}" => {
      zone    = pair[0]
      vnet_id = pair[1]
    }
  }

  resource_group_name = local.rg_name
  tags                = var.tags

  name                  = "link-${local.vnets[each.value.vnet_id].name}"
  private_dns_zone_name = azurerm_private_dns_zone.this[each.value.zone].name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = false
}
