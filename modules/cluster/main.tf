# Cloud Cluster
resource "local_file" "group_vars" {
  content = templatefile("./ansible/templates/group_vars.tpl",
    {
      subnet_cidr  = var.subnet_cidr
      cluster_name = var.cluster_name
    }
  )
  filename = "./ansible/group_vars/${var.cluster_name}"
}

resource "local_file" "hosts" {
  content = templatefile("./ansible/templates/hosts.tpl",
    {
      cluster_name     = var.cluster_name
      master_instances = module.master.instances
      worker_instances = module.worker.instances
    }
  )
  filename = "./ansible/${var.cluster_name}_hosts.ini"
}

# Local variables to reduce duplicates
locals {
  secgroup_name = "${var.cluster_name}_sg"
  network_name  = "${var.cluster_name}_network"
}

# Create the network
module "networking" {
  source               = "../networking"
  private_network_name = local.network_name
  subnet_name          = "${var.cluster_name}_subnet"
  subnet_cidr          = var.subnet_cidr
  public_network_name  = var.public_network_name
  router_name          = "${var.cluster_name}_router"
  secgroup_name        = local.secgroup_name
  secgroup_description = var.secgroup_description
  secgroup_rules       = var.secgroup_rules

}

# Create the compute instance
module "master" {
  source                                      = "../compute"
  instance_depends_on                         = [module.networking.subnet, local_file.group_vars]
  cluster_name                                = var.cluster_name
  instance_role                               = "master"
  instance_count                              = var.master_count
  instance_image_id                           = var.instance_image_id
  instance_flavor_name                        = var.instance_flavor_name
  instance_keypair_name                       = var.instance_keypair_name
  instance_availability_zone                  = var.instance_availability_zone
  instance_block_device_source_type           = var.instance_block_device_source_type
  instance_block_device_volume_size           = var.instance_block_device_volume_size
  instance_block_device_boot_index            = var.instance_block_device_boot_index
  instance_block_device_destination_type      = var.instance_block_device_destination_type
  instance_block_device_delete_on_termination = var.instance_block_device_delete_on_termination
  secgroup_name                               = local.secgroup_name
  network_name                                = local.network_name
  instance_user                               = var.instance_user
  ssh_key_file                                = var.ssh_key_file
  floatingip_pool                             = var.floatingip_pool
}

module "worker" {
  source                                      = "../compute"
  instance_depends_on                         = [module.networking.subnet, local_file.group_vars]
  cluster_name                                = var.cluster_name
  instance_role                               = "worker"
  instance_count                              = var.worker_count
  instance_image_id                           = var.instance_image_id
  instance_flavor_name                        = var.instance_flavor_name
  instance_keypair_name                       = var.instance_keypair_name
  instance_availability_zone                  = var.instance_availability_zone
  instance_block_device_source_type           = var.instance_block_device_source_type
  instance_block_device_volume_size           = var.instance_block_device_volume_size
  instance_block_device_boot_index            = var.instance_block_device_boot_index
  instance_block_device_destination_type      = var.instance_block_device_destination_type
  instance_block_device_delete_on_termination = var.instance_block_device_delete_on_termination
  secgroup_name                               = local.secgroup_name
  network_name                                = local.network_name
  instance_user                               = var.instance_user
  ssh_key_file                                = var.ssh_key_file
  floatingip_pool                             = var.floatingip_pool
}

# Run Ansible
resource "null_resource" "ansible_master" {
  count = var.master_count
  triggers = {
    master_instance_id = module.master.instances[count.index].id
  }

  provisioner "remote-exec" {
    inline = ["#Connected"]

    connection {
      user        = var.instance_user
      host        = module.master.instances[count.index].floating_ip
      private_key = file(var.ssh_key_file)
      agent       = "true"
    }
  }

  provisioner "local-exec" {
    command = <<EOT
    cd ansible;
    ansible-playbook -i ${var.cluster_name}_hosts.ini master.yml
    EOT
  }
}

resource "null_resource" "ansible_worker" {
  count = var.worker_count
  triggers = {
    worker_instance_id = module.worker.instances[count.index].id
  }

  provisioner "remote-exec" {
    inline = ["#Connected"]

    connection {
      user        = var.instance_user
      host        = module.worker.instances[count.index].floating_ip
      private_key = file(var.ssh_key_file)
      agent       = "true"
    }
  }

  provisioner "local-exec" {
    command = <<EOT
    cd ansible;
    ansible-playbook -i ${var.cluster_name}_hosts.ini worker.yml
    EOT
  }
}

# Cleanup resources
resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
     rm -rf ./ansible/from_remote/*
     EOT
  }
}
