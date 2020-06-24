output "subnet" {
  value = openstack_networking_subnet_v2.subnet
}

output "floatingip_address" {
  value = openstack_networking_floatingip_v2.floatingip.address
}
