<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Reverse Private DNS Zone

Reverse DNS as an overlay on existing networks: vnet ids in, derived in-addr.arpa zones out,
linked back estate-wide.

[![CI](https://github.com/libre-devops/terraform-azurerm-reverse-private-dns-zone/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-reverse-private-dns-zone/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-reverse-private-dns-zone?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-reverse-private-dns-zone/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-reverse-private-dns-zone)](./LICENSE)

---

## Overview

Reverse lookup zones are usually an afterthought bolted on long after the networks exist, and
deriving `0.70.10.in-addr.arpa` from `10.70.0.0/24` by hand is exactly the arithmetic humans
get wrong. This module is the attach pattern (the relationship subnet has to network, or
nsg-rules to nsg): it adds reverse DNS to infrastructure you already have, touching nothing.

- **Vnet ids in, zones out**: each existing vnet's address space is read, the smallest
  octet-boundary zone containing each CIDR is derived (a /24 gets its exact zone; a non-octet
  /22 lands in its containing /16, which a `check` points out; wider than /8 clamps to the /8
  of the network address), and duplicates collapse across vnets. Because the vnets already
  exist, every derived name is plan-known.
- **Estate-wide resolution**: every vnet links to every derived zone, so reverse lookups
  resolve across the estate rather than only for a vnet's own ranges. Auto-registration stays
  off on principle: Azure only auto-registers forward records, and a vnet's single
  registration-enabled link belongs to its forward zone.
- **PTR content composes in**: `zones_per_virtual_network` maps each vnet to its zones, made
  for the private-dns-records module's `ptr_records`. Greenfield stacks that know their CIDRs
  up front should use private-dns-zone's `reverse_dns_zone_cidrs` instead; this module is for
  the estate that already exists.

The examples are runnable: `minimal` overlays one /24 vnet; `complete` overlays an octet-aligned
/24 alongside a deliberately non-octet /22 and proves the derived zone with a PTR record.

<!-- BEGIN_TF_DOCS -->
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

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_private_dns_zone.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Id of the resource group the derived zones and links land in; the name is parsed from the id. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_virtual_network_ids"></a> [virtual\_network\_ids](#input\_virtual\_network\_ids) | Ids of EXISTING virtual networks to overlay with reverse DNS. This module is the attach<br/>pattern (the relationship subnet has to network, or nsg-rules to nsg): it reads each vnet's<br/>address space, derives the smallest octet-boundary in-addr.arpa zone containing each CIDR<br/>(10.70.0.0/24 gives 0.70.10.in-addr.arpa; a non-octet /22 lands in its containing /16<br/>zone), deduplicates across vnets, creates the zones, and links every vnet to every derived<br/>zone so reverse lookups resolve estate-wide. Links never enable auto-registration: Azure<br/>only auto-registers forward records, and a vnet's single registration link must stay with<br/>its forward zone. Populate PTR content with the private-dns-records module. Greenfield<br/>stacks that know their CIDRs up front should use private-dns-zone's reverse\_dns\_zone\_cidrs<br/>instead. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_reverse_zone_ids"></a> [reverse\_zone\_ids](#output\_reverse\_zone\_ids) | Map of derived reverse zone name to its id (feed these to private-dns-records for PTR content). |
| <a name="output_reverse_zone_names"></a> [reverse\_zone\_names](#output\_reverse\_zone\_names) | The derived in-addr.arpa zone names. |
| <a name="output_virtual_network_link_ids"></a> [virtual\_network\_link\_ids](#output\_virtual\_network\_link\_ids) | Map of zone\|vnet link key to its id. |
| <a name="output_zones_per_virtual_network"></a> [zones\_per\_virtual\_network](#output\_zones\_per\_virtual\_network) | Map of vnet id to the reverse zones derived from its address space, for composing PTR records per network. |
<!-- END_TF_DOCS -->
