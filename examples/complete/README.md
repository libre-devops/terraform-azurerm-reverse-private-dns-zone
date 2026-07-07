<!--
  Header for the complete example README. Edit this file, then run `just docs`
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

# Complete example

Overlays two vnets: an octet-aligned /24 (exact classful zone) and a deliberately non-octet
/22 (the documented classless dash-form zone, 0-22.114.10.in-addr.arpa), with the mesh of
links and a PTR record proving the derived zone resolves. The environment comes from the Terraform workspace
(`terraform.workspace`), not a variable. Run it with `just e2e complete`, which applies the stack
then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-003"
  zone_a   = "0.113.10.in-addr.arpa"

  # The EXISTING estate from the prereq stack, referenced by constructed ids: an octet-aligned
  # /24 (exact classful zone) and a deliberately non-octet /22 (the documented classless
  # dash-form zone derives: 0-22.114.10.in-addr.arpa).
  estate_rg = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  vnet_a    = "vnet-${var.short}-${var.loc}-${terraform.workspace}-003"
  vnet_b    = "vnet-${var.short}-${var.loc}-${terraform.workspace}-004"
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

# Complete call: both estate vnets overlaid. Two derived zones (the /24's exact classful zone
# and the /22's classless dash-form zone), every vnet linked to every zone for estate-wide
# reverse resolution.
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0.0, < 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_reverse_dns"></a> [reverse\_dns](#module\_reverse\_dns) | ../../ | n/a |
| <a name="module_rg"></a> [rg](#module\_rg) | libre-devops/rg/azurerm | ~> 4.0 |
| <a name="module_tags"></a> [tags](#module\_tags) | libre-devops/tags/azurerm | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_private_dns_ptr_record.app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_ptr_record) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

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
| <a name="output_reverse_zone_ids"></a> [reverse\_zone\_ids](#output\_reverse\_zone\_ids) | Map of derived zone name to id. |
| <a name="output_zones_per_virtual_network"></a> [zones\_per\_virtual\_network](#output\_zones\_per\_virtual\_network) | Map of vnet id to its derived zones. |
<!-- END_TF_DOCS -->
