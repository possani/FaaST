output "associate_floating_ip-floating_ip" {
  value = openstack_compute_floatingip_associate_v2.floatingip_associate_instance.floating_ip
}
