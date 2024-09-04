output "dns_number_of_record_sets" {
  description = "The max number of virtual network links with registration"
  value       = values(azurerm_private_dns_zone.reverse_dns_zone)[*].number_of_record_sets
}

output "dns_zone_id" {
  description = "The dns zone ids"
  value       = values(azurerm_private_dns_zone.reverse_dns_zone)[*].id
}

output "dns_zone_max_number_of_record_sets" {
  description = "The max number of record sets"
  value       = values(azurerm_private_dns_zone.reverse_dns_zone)[*].max_number_of_record_sets
}

output "dns_zone_max_number_of_virtual_network_links" {
  description = "The dns max number of virtual network links"
  value       = values(azurerm_private_dns_zone.reverse_dns_zone)[*].max_number_of_virtual_network_links
}

output "dns_zone_max_number_of_virtual_network_links_with_registration" {
  description = "The max number of virtual network links with registration"
  value       = values(azurerm_private_dns_zone.reverse_dns_zone)[*].max_number_of_virtual_network_links_with_registration
}

output "dns_zone_name" {
  description = "The dns zone name"
  value       = values(azurerm_private_dns_zone.reverse_dns_zone)[*].name
}

output "vnet_link_id" {
  description = "The vnet link ids"
  value       = values(azurerm_private_dns_zone_virtual_network_link.reverse_dns_zone_link)[*].id
}
