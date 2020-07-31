output "master_instance" {
  value = module.master.instances
}

output "worker_instances" {
  value = module.worker.instances
}

# output "loadbalancer_service_ip" {
#   value = module.networking.service_ip
# }