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

- **Vnet ids in, zones out**: each existing vnet's address space is read and its zone derived.
  Octet-aligned CIDRs get their exact classful zone (a /24 like 10.70.0.0/24 gives
  0.70.10.in-addr.arpa). Non-octet CIDRs default to the documented classless dash form, exact
  to the range (192.0.2.128/26 gives 128-26.2.0.192.in-addr.arpa, a /22 gives
  0-22.114.10.in-addr.arpa, per the Azure private reverse DNS guidance);
  use_classless_zones = false falls back to the smallest containing classful zone, which a
  check points out because it shadows reverse resolution for the whole containing range.
  Duplicates collapse across vnets, and because the vnets already exist, every derived name is
  plan-known.
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
