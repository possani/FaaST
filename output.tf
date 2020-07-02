output "cloud_master_floatingip_address" {
  value = module.cloud_master.floatingip_address
}

output "cloud_worker_floatingip_address" {
  value = module.cloud_worker.floatingip_address
}


# output "edge_floatingip_address" {
#   value = module.edge_networking.floatingip_address
# }
