variable "resource_group_id" {
  description = "Id of the resource group the derived zones and links land in; the name is parsed from the id."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "virtual_network_ids" {
  description = <<-EOT
    Ids of EXISTING virtual networks to overlay with reverse DNS. This module is the attach
    pattern (the relationship subnet has to network, or nsg-rules to nsg): it reads each vnet's
    address space, derives the smallest octet-boundary in-addr.arpa zone containing each CIDR
    (10.70.0.0/24 gives 0.70.10.in-addr.arpa; a non-octet /22 lands in its containing /16
    zone), deduplicates across vnets, creates the zones, and links every vnet to every derived
    zone so reverse lookups resolve estate-wide. Links never enable auto-registration: Azure
    only auto-registers forward records, and a vnet's single registration link must stay with
    its forward zone. Populate PTR content with the private-dns-records module. Greenfield
    stacks that know their CIDRs up front should use private-dns-zone's reverse_dns_zone_cidrs
    instead. ONE OVERLAY PER VNET: Azure refuses to link a vnet to two zones with the same
    namespace, so a vnet overlaid here must not be overlaid again by another stack or zone set
    (BadRequest, caught live).
  EOT
  type        = list(string)

  validation {
    condition     = length(var.virtual_network_ids) > 0
    error_message = "Pass at least one virtual network id; the overlay derives everything from them."
  }

  validation {
    condition = alltrue([
      for id in var.virtual_network_ids :
      can(regex("(?i)/providers/Microsoft.Network/virtualNetworks/[^/]+$", id))
    ])
    error_message = "Every entry must be a virtual network resource id."
  }
}
