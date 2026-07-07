output "vnet_ids" {
  description = "The estate vnet ids the overlay examples attach to."
  value       = { a = module.network_a.vnet_id, b = module.network_b.vnet_id }
}
