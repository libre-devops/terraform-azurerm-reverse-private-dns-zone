locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  vnet_a   = "vnet-${var.short}-${var.loc}-${terraform.workspace}-001"
  vnet_b   = "vnet-${var.short}-${var.loc}-${terraform.workspace}-002"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# The "existing estate" the overlay examples attach to: the overlay reads vnets that must exist
# BEFORE it plans (its zone names derive from their address spaces), so this stack applies
# first in CI and is destroyed last.
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
