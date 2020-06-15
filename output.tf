output "associate_floating_ip-floating_ip" {
  value = openstack_compute_floatingip_associate_v2.floatingip_associate_instance.floating_ip
}

output "instance-access_ip_v4" {
  value = openstack_compute_instance_v2.instance.access_ip_v4
}
