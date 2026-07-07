output "reverse_zone_ids" {
  description = "Map of derived zone name to id."
  value       = module.reverse_dns.reverse_zone_ids
}

output "zones_per_virtual_network" {
  description = "Map of vnet id to its derived zones."
  value       = module.reverse_dns.zones_per_virtual_network
}
