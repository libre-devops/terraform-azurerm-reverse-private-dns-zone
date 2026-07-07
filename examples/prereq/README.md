<!--
  Header for the minimal example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Prereq example

The "existing estate" the overlay examples attach to: two vnets (an octet-aligned /24 and a
non-octet /22) that must exist BEFORE the overlay stacks plan, because the overlay derives its
zone names from their address spaces. Applied first in CI, destroyed last. The environment comes from the
Terraform workspace (`terraform.workspace`), not a variable. Run it with `just e2e prereq`, which
applies the stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_network_a"></a> [network\_a](#module\_network\_a) | libre-devops/network/azurerm | ~> 4.0 |
| <a name="module_network_b"></a> [network\_b](#module\_network\_b) | libre-devops/network/azurerm | ~> 4.0 |
| <a name="module_rg"></a> [rg](#module\_rg) | libre-devops/rg/azurerm | ~> 4.0 |
| <a name="module_tags"></a> [tags](#module\_tags) | libre-devops/tags/azurerm | ~> 4.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployed_branch"></a> [deployed\_branch](#input\_deployed\_branch) | Git branch the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_branch. | `string` | `""` | no |
| <a name="input_deployed_repo"></a> [deployed\_repo](#input\_deployed\_repo) | Repository URL the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_repo. | `string` | `""` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | Outfix: short Azure region code used in resource names (for example uks). | `string` | `"uks"` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Map of short region codes to Azure region slugs. | `map(string)` | <pre>{<br/>  "eus": "eastus",<br/>  "euw": "westeurope",<br/>  "uks": "uksouth",<br/>  "ukw": "ukwest"<br/>}</pre> | no |
| <a name="input_short"></a> [short](#input\_short) | Infix: short product code used in resource names. | `string` | `"ldo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vnet_ids"></a> [vnet\_ids](#output\_vnet\_ids) | The estate vnet ids the overlay examples attach to. |
<!-- END_TF_DOCS -->
