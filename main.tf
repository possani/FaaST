## Configure the OpenStack Provider
provider "openstack" {
  cloud = "openstack"
}

## Create network
resource "openstack_networking_network_v2" "cloud_network" {
  name                  = var.cloud_network_name
  admin_state_up        = "true"
  port_security_enabled = "true"
}

## Create subnet
resource "openstack_networking_subnet_v2" "cloud_subnet" {
  name       = var.cloud_subnet_name
  cidr       = var.cloud_subnet_cidr
  network_id = openstack_networking_network_v2.cloud_network.id
  ip_version = 4
}

## Get public network info
data "openstack_networking_network_v2" "public_network" {
  name = var.public_network_name
}

## Create a router
resource "openstack_networking_router_v2" "cloud_router" {
  name                = var.cloud_router_name
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public_network.id
}

## Give internet access to the subnet
resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.cloud_router.id
  subnet_id = openstack_networking_subnet_v2.cloud_subnet.id
}

## Create a Floating IP
resource "openstack_networking_floatingip_v2" "floatingip" {
  pool = var.floatingip_pool
}

## Create a Virtual Machine
resource "openstack_compute_instance_v2" "instance" {
  depends_on = [openstack_networking_subnet_v2.cloud_subnet]

  name              = var.instance_name
  flavor_name       = var.instance_flavor_name
  key_pair          = var.instance_keypair_name
  availability_zone = var.instance_availability_zone
  security_groups   = ["default", var.k8s_secgroup_name]

  block_device {
    uuid                  = var.instance_image_id
    source_type           = var.instance_block_device_source_type
    volume_size           = var.instance_block_device_volume_size
    boot_index            = var.instance_block_device_boot_index
    destination_type      = var.instance_block_device_destination_type
    delete_on_termination = var.instance_block_device_delete_on_termination
  }

  network {
    name = var.cloud_network_name
  }
}

## Create a Floating IP association
resource "openstack_compute_floatingip_associate_v2" "floatingip_associate_instance" {
  floating_ip = openstack_networking_floatingip_v2.floatingip.address
  instance_id = openstack_compute_instance_v2.instance.id
}

## Create a Secutiry Group for k8s
resource "openstack_networking_secgroup_v2" "k8s_secgroup" {
  name        = var.k8s_secgroup_name
  description = var.k8s_secgroup_description
}

## Create a Secutiry Group Rules for k8s
resource "openstack_networking_secgroup_rule_v2" "k8s_secgroup_rules" {
  count = length(var.k8s_secgroup_rules)

  direction = "ingress"
  ethertype = "IPv4"

  protocol          = var.k8s_secgroup_rules[count.index].ip_protocol
  port_range_min    = var.k8s_secgroup_rules[count.index].port
  port_range_max    = var.k8s_secgroup_rules[count.index].port
  remote_ip_prefix  = var.k8s_secgroup_rules[count.index].cidr
  security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
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
