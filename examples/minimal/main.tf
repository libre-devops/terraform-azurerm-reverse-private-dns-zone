locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"

  # The EXISTING vnet from the prereq stack, referenced by its constructed id: the overlay
  # reads networks that must exist before it plans, which is the module's contract (real
  # callers pass ids from another stack's outputs or remote state).
  estate_rg = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  vnet_a    = "vnet-${var.short}-${var.loc}-${terraform.workspace}-001"
  vnet_a_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.estate_rg}/providers/Microsoft.Network/virtualNetworks/${local.vnet_a}"
}

data "azurerm_client_config" "current" {}

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

# Minimal call: one existing vnet in, its derived reverse zone (0.111.10.in-addr.arpa) out,
# linked back.
module "reverse_dns" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  tags              = module.tags.tags

  virtual_network_ids = [local.vnet_a_id]
}
