output "reverse_zone_names" {
  description = "The derived reverse zone names."
  value       = module.reverse_dns.reverse_zone_names
}
