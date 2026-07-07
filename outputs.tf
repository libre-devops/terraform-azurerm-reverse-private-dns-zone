output "reverse_zone_ids" {
  description = "Map of derived reverse zone name to its id (feed these to private-dns-records for PTR content)."
  value       = { for k, v in azurerm_private_dns_zone.this : k => v.id }
}

output "reverse_zone_names" {
  description = "The derived in-addr.arpa zone names."
  value       = local.reverse_zones
}

output "virtual_network_link_ids" {
  description = "Map of zone|vnet link key to its id."
  value       = { for k, v in azurerm_private_dns_zone_virtual_network_link.this : k => v.id }
}

output "zones_per_virtual_network" {
  description = "Map of vnet id to the reverse zones derived from its address space, for composing PTR records per network."
  value       = local.zones_per_vnet
}
