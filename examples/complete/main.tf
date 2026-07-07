locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-003"
  zone_a   = "0.111.10.in-addr.arpa"

  # The EXISTING estate from the prereq stack, referenced by constructed ids: an octet-aligned
  # /24 and a deliberately non-octet /22 (its containing /16 zone derives, and the module's
  # check points out the wider coverage).
  estate_rg = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  vnet_a    = "vnet-${var.short}-${var.loc}-${terraform.workspace}-001"
  vnet_b    = "vnet-${var.short}-${var.loc}-${terraform.workspace}-002"
  vnet_ids = [
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.estate_rg}/providers/Microsoft.Network/virtualNetworks/${local.vnet_a}",
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.estate_rg}/providers/Microsoft.Network/virtualNetworks/${local.vnet_b}",
  ]
}

data "azurerm_client_config" "current" {}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-reverse-private-dns-zone" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# Complete call: both estate vnets overlaid. Two derived zones (the /24's exact zone and the
# /22's containing /16), every vnet linked to every zone for estate-wide reverse resolution.
module "reverse_dns" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  tags              = module.tags.tags

  virtual_network_ids = local.vnet_ids
}

# PTR content proving the derived zone resolves; the private-dns-records module is the typed
# surface for populating these at scale (its ptr_records input pairs with
# zones_per_virtual_network).
resource "azurerm_private_dns_ptr_record" "app" {
  resource_group_name = local.rg_name
  tags                = module.tags.tags

  name      = "4"
  zone_name = local.zone_a
  ttl       = 300
  records   = ["app.corp.example.internal"]

  depends_on = [module.reverse_dns]
}
