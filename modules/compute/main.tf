# Create a Virtual Machine
resource "openstack_compute_instance_v2" "instance" {
  depends_on = [var.instance_depends_on]

  name              = var.instance_name
  flavor_name       = var.instance_flavor_name
  key_pair          = var.instance_keypair_name
  availability_zone = var.instance_availability_zone
  security_groups   = ["default", var.secgroup_name]
  user_data         = "#cloud-config\nhostname: ${var.instance_name}\nfqdn: ${var.instance_name}"

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

# Create a Floating IP association
resource "openstack_compute_floatingip_associate_v2" "floatingip_associate_instance" {
  floating_ip = var.floatingip_address
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
      host        = var.floatingip_address
      private_key = file(var.ssh_key_file)
      agent       = "true"
    }
  }


  provisioner "local-exec" {
    command = <<EOT

      # Add entry to the hosts file
      cd ansible;
      printf "\n[${var.cluster_name}]\n${var.instance_name} ansible_ssh_host=${var.floatingip_address}" > ${var.cluster_name}.ini

      # Run Playbook
      ansible-playbook -i ${var.cluster_name}.ini site.yml

    EOT
  }
}
