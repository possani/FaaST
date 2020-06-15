## Configure the OpenStack Provider
provider "openstack" {
  cloud = "openstack"
}

## Create a Floating IP
resource "openstack_networking_floatingip_v2" "floatingip" {
  pool = var.floatingip_pool
}

## Create a Virtual Machine
resource "openstack_compute_instance_v2" "instance" {
  name              = var.instance_name
  flavor_name       = var.instance_flavor_name
  key_pair          = var.instance_keypair_name
  availability_zone = var.instance_availability_zone
  security_groups   = ["default", var.rke_secgroup_name]

  block_device {
    uuid                  = var.instance_image_id
    source_type           = var.instance_block_device_source_type
    volume_size           = var.instance_block_device_volume_size
    boot_index            = var.instance_block_device_boot_index
    destination_type      = var.instance_block_device_destination_type
    delete_on_termination = var.instance_block_device_delete_on_termination
  }

  network {
    name = var.instance_network
  }
}

## Create a Floating IP association
resource "openstack_compute_floatingip_associate_v2" "floatingip_associate_instance" {
  floating_ip = openstack_networking_floatingip_v2.floatingip.address
  instance_id = openstack_compute_instance_v2.instance.id
}

## Create a Secutiry Group for rke
resource "openstack_networking_secgroup_v2" "rke_secgroup" {
  name        = var.rke_secgroup_name
  description = var.rke_secgroup_description
}

## Create a Secutiry Group Rules for rke
resource "openstack_networking_secgroup_rule_v2" "rke_secgroup_rules" {
  count = length(var.rke_secgroup_rules)

  direction = "ingress"
  ethertype = "IPv4"

  protocol          = var.rke_secgroup_rules[count.index].ip_protocol
  port_range_min    = var.rke_secgroup_rules[count.index].port
  port_range_max    = var.rke_secgroup_rules[count.index].port
  remote_ip_prefix  = var.rke_secgroup_rules[count.index].cidr
  security_group_id = openstack_networking_secgroup_v2.rke_secgroup.id
}

resource "null_resource" "ansible" {
  triggers = {
    node_instance_id = openstack_compute_instance_v2.instance.id
  }

  provisioner "remote-exec" {
    inline = ["#Connected"]

    connection {
      user        = var.cloud_cluster_user
      host        = openstack_networking_floatingip_v2.floatingip.address
      private_key = file(var.cloud_cluster_ssh_key)
      agent       = "true"
    }
  }

  provisioner "local-exec" {
    command = <<EOT

      # Add entry to the hosts file
      cd ansible;
      touch hosts;
      printf "\n[cloud]\n${var.instance_name} ansible_ssh_host=${openstack_networking_floatingip_v2.floatingip.address}" >> hosts

      # Run Playbook
      ansible-playbook site.yml

    EOT
  }
}
