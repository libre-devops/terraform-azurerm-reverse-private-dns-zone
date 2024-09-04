```hcl
locals {
  #The below locals convert an IP address range into separate elements.  Take 10.0.2.0/24 for example:
  first_octet = var.create_reverse_dns_zone == true && var.address_range != null ? element(split(".", element(var.address_range, 0)), 0) : null
  # Gets the first octet of range, so for example, 10
  second_octet = var.create_reverse_dns_zone == true && var.address_range != null ? element(split(".", element(var.address_range, 0)), 1) : null
  # Gets the second octet of range, so for example, 0
  third_octet = var.create_reverse_dns_zone == true && var.address_range != null ? element(split(".", element(var.address_range, 0)), 2) : null
  # Gets the third octet of range, so for example, 2
  fourth_element = var.create_reverse_dns_zone == true && var.address_range != null ? element(split(".", element(var.address_range, 0)), 3) : null
  # Gets the forth element of range, so for example, 0/24
  fourth_octet = var.create_reverse_dns_zone == true && var.address_range != null && local.fourth_element != null ? element(split("/", local.fourth_element), 0) : null
  # Gets the fourth element of range, so for example, 0
  cidr_range = var.create_reverse_dns_zone == true && var.address_range != null && local.fourth_element != null ? element(split("/", local.fourth_element), 1) : null
  # Gets the the cidr portion of the range, so for example, 24

  # Reconstructs the name using above elements to create, for example, 24-0.2.0.10.in-addr.arpa
  reverse_zone_name = var.create_reverse_dns_zone == true && var.address_range != null ? format("%d-%d.%d.%d.%d.in-addr.arpa", local.cidr_range, local.fourth_octet, local.third_octet, local.second_octet, local.first_octet) : null
}

resource "azurerm_private_dns_zone" "reverse_dns_zone" {
  for_each = var.create_reverse_dns_zone == true && var.address_range != null ? toset(var.address_range) : []

  name                = local.reverse_zone_name
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "reverse_dns_zone_link" {
  for_each              = try(var.link_to_vnet, true) == true && var.create_reverse_dns_zone == true && var.address_range != null ? toset(var.address_range) : []
  name                  = var.vnet_link_name == null ? "${lower(replace(azurerm_private_dns_zone.reverse_dns_zone[each.key].name, ".", "-"))}-link-to-${local.vnet_name}" : try(var.vnet_link_name, null)
  resource_group_name   = try(var.rg_name, null)
  private_dns_zone_name = azurerm_private_dns_zone.reverse_dns_zone[each.key].name
  virtual_network_id    = try(var.vnet_id, null)
  tags                  = try(var.tags, null)
}

resource "azurerm_private_dns_zone_virtual_network_link" "reverse_dns_zone_link_hub" {
  for_each              = try(var.link_to_vnet, true) == true && var.create_reverse_dns_zone == true && var.attempt_reverse_dns_dns_zone_link_to_hub == true && var.address_range != null ? toset(var.address_range) : []
  name                  = var.vnet_link_name == null ? "${lower(replace(azurerm_private_dns_zone.reverse_dns_zone[each.key].name, ".", "-"))}-link-to-${local.hub_vnet_name}" : try(var.vnet_link_name, null)
  resource_group_name   = try(var.rg_name, null)
  private_dns_zone_name = azurerm_private_dns_zone.reverse_dns_zone[each.key].name
  virtual_network_id    = try(var.hub_vnet_id, null)
  tags                  = try(var.tags, null)
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_private_dns_zone.reverse_dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.reverse_dns_zone_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.reverse_dns_zone_link_hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_range"></a> [address\_range](#input\_address\_range) | If creating a reverse DNS zone, provide this input with a full cidr range, e.g. 10.0.0.0/16, as it will be split and made if the create\_reverse\_dns\_zone variable is set to true | `list(string)` | `null` | no |
| <a name="input_attempt_reverse_dns_dns_zone_link_to_hub"></a> [attempt\_reverse\_dns\_dns\_zone\_link\_to\_hub](#input\_attempt\_reverse\_dns\_dns\_zone\_link\_to\_hub) | Whether the DNS zone being made should be linked to the hub | `bool` | `false` | no |
| <a name="input_create_reverse_dns_zone"></a> [create\_reverse\_dns\_zone](#input\_create\_reverse\_dns\_zone) | Whether or not to create a reverse DNS zone, defaults to false | `bool` | `false` | no |
| <a name="input_hub_vnet_id"></a> [hub\_vnet\_id](#input\_hub\_vnet\_id) | The ID of the hub vnet | `string` | `null` | no |
| <a name="input_link_to_vnet"></a> [link\_to\_vnet](#input\_link\_to\_vnet) | Whether or not the zone should be linked to the vnet, defaults to false | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | The location for this resource to be put in | `string` | n/a | yes |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of the tags to use on the resources that are deployed with this module. | `map(string)` | n/a | yes |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | The vnet id the dns zones should be linked to | `string` | `null` | no |
| <a name="input_vnet_link_name"></a> [vnet\_link\_name](#input\_vnet\_link\_name) | The name of the vnet link if one is made, defaults to null | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_number_of_record_sets"></a> [dns\_number\_of\_record\_sets](#output\_dns\_number\_of\_record\_sets) | The max number of virtual network links with registration |
| <a name="output_dns_zone_id"></a> [dns\_zone\_id](#output\_dns\_zone\_id) | The dns zone ids |
| <a name="output_dns_zone_max_number_of_record_sets"></a> [dns\_zone\_max\_number\_of\_record\_sets](#output\_dns\_zone\_max\_number\_of\_record\_sets) | The max number of record sets |
| <a name="output_dns_zone_max_number_of_virtual_network_links"></a> [dns\_zone\_max\_number\_of\_virtual\_network\_links](#output\_dns\_zone\_max\_number\_of\_virtual\_network\_links) | The dns max number of virtual network links |
| <a name="output_dns_zone_max_number_of_virtual_network_links_with_registration"></a> [dns\_zone\_max\_number\_of\_virtual\_network\_links\_with\_registration](#output\_dns\_zone\_max\_number\_of\_virtual\_network\_links\_with\_registration) | The max number of virtual network links with registration |
| <a name="output_dns_zone_name"></a> [dns\_zone\_name](#output\_dns\_zone\_name) | The dns zone name |
| <a name="output_vnet_link_id"></a> [vnet\_link\_id](#output\_vnet\_link\_id) | The vnet link ids |
