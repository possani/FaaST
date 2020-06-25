output "cloud_floatingip_address" {
  value = module.cloud_networking.floatingip_address
}

output "edge_floatingip_address" {
  value = module.edge_networking.floatingip_address
}
