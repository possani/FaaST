# Create a Virtual Machine
resource "openstack_compute_instance_v2" "instance" {
  depends_on = [var.instance_depends_on]

  name              = "${var.cluster_name}-${var.instance_role}"
  flavor_name       = var.instance_flavor_name
  key_pair          = var.instance_keypair_name
  availability_zone = var.instance_availability_zone
  security_groups   = ["default", var.secgroup_name]
  user_data         = "#cloud-config\nhostname: ${var.cluster_name}-${var.instance_role}\nfqdn: ${var.cluster_name}-${var.instance_role}"

  block_device {
    uuid                  = var.instance_image_id
    source_type           = var.instance_block_device_source_type
    volume_size           = var.instance_block_device_volume_size
    boot_index            = var.instance_block_device_boot_index
    destination_type      = var.instance_block_device_destination_type
    delete_on_termination = var.instance_block_device_delete_on_termination
  }

  network {
    name = var.network_name
  }
}

# Create a Floating IP
resource "openstack_networking_floatingip_v2" "floatingip" {
  pool = var.floatingip_pool
}

# Create a Floating IP association
resource "openstack_compute_floatingip_associate_v2" "floatingip_associate_instance" {
  floating_ip = openstack_networking_floatingip_v2.floatingip.address
  instance_id = openstack_compute_instance_v2.instance.id
}

# Run Ansible
resource "null_resource" "ansible" {
  triggers = {
    node_instance_id = openstack_compute_instance_v2.instance.id
  }

  provisioner "remote-exec" {
    inline = ["#Connected"]

    connection {
      user        = var.instance_user
      host        = openstack_networking_floatingip_v2.floatingip.address
      private_key = file(var.ssh_key_file)
      agent       = "true"
    }
  }


  provisioner "local-exec" {
    command = <<EOT

      # Add entry to the hosts file
      cd ansible;
      printf "[${var.cluster_name}:children]\n${var.instance_role}\n" > ${openstack_compute_instance_v2.instance.name}.ini
      printf "[${var.instance_role}]\n${openstack_compute_instance_v2.instance.name} ansible_ssh_host=${openstack_networking_floatingip_v2.floatingip.address} ansible_python_interpreter=/usr/bin/python3" >> ${openstack_compute_instance_v2.instance.name}.ini

      # Run Playbook
      ansible-playbook -i ${openstack_compute_instance_v2.instance.name}.ini site.yml

    EOT
  }
}
