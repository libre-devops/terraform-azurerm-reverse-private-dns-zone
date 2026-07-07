locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  vnet_a   = "vnet-${var.short}-${var.loc}-${terraform.workspace}-002"
  vnet_b   = "vnet-${var.short}-${var.loc}-${terraform.workspace}-003"
  zone_a   = "0.111.10.in-addr.arpa"
}

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

# Two "existing" vnets: one octet-aligned /24, one deliberately non-octet /22 to show the
# containing-zone semantics (it lands in its /16 zone, and the module's check points it out).
module "network_a" {
  source  = "libre-devops/network/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  vnet_name     = local.vnet_a
  address_space = ["10.111.0.0/24"]

  subnets = {
    "snet-app-${local.vnet_a}" = {
      address_prefixes = ["10.111.0.0/27"]
    }
  }
}

module "network_b" {
  source  = "libre-devops/network/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  vnet_name     = local.vnet_b
  address_space = ["10.112.0.0/22"]

  subnets = {
    "snet-app-${local.vnet_b}" = {
      address_prefixes = ["10.112.0.0/27"]
    }
  }
}

# Complete call: both vnets overlaid. Three derived zones (the /24's own zone, the /22's
# containing /16 zone), every vnet linked to every zone for estate-wide reverse resolution.
module "reverse_dns" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  tags              = module.tags.tags

  virtual_network_ids = [
    module.network_a.vnet_id,
    module.network_b.vnet_id,
  ]
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
