# Configure the OpenStack provider
provider "openstack" {
  cloud = "openstack"
}

# Cloud Cluster
data "template_file" "cloud_group_vars" {
  template = "${file("./ansible/templates/group_vars.tpl")}"
  vars = {
    subnet_cidr  = var.subnet_cidr
    cluster_name = var.cluster_name
  }
}

resource "local_file" "cloud_group_vars" {
  content  = data.template_file.cloud_group_vars.rendered
  filename = "./ansible/group_vars/cloud"
}

# data "template_file" "cloud_hosts" {
#   template = "${file("./hosts.tpl")}"
#   depends_on = [ module.cloud_master, module.cloud_worker ]

#   vars = {
#     cluster_name = var.cluster_name
#     master_instances  = module.cloud_master.instances
#     worker_instances  = module.cloud_worker.instances
#   }
# }

resource "local_file" "cloud_hosts" {
  content = templatefile("./ansible/templates/hosts.tpl",
    {
      cluster_name = var.cluster_name
      master_instances  = module.cloud_master.instances
      worker_instances  = module.cloud_worker.instances
    }
  )
  filename = "./ansible/cloud_hosts.ini"
}

# Create the network
module "cloud_networking" {
  source               = "./modules/networking"
  private_network_name = "${var.cluster_name}_network"
  subnet_name          = "${var.cluster_name}_subnet"
  subnet_cidr          = var.subnet_cidr
  public_network_name  = var.public_network_name
  router_name          = "${var.cluster_name}_router"
  secgroup_name        = "${var.cluster_name}_sg"
  secgroup_description = var.secgroup_description
  secgroup_rules       = var.secgroup_rules

}

# Create the compute instance
module "cloud_master" {
  source                                      = "./modules/compute"
  instance_depends_on                         = [module.cloud_networking.subnet, local_file.cloud_group_vars]
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
  secgroup_name                               = "${var.cluster_name}_sg"
  network_name                                = "${var.cluster_name}_network"
  instance_user                               = var.instance_user
  ssh_key_file                                = var.ssh_key_file
  floatingip_pool                             = var.floatingip_pool
}

module "cloud_worker" {
  source                                      = "./modules/compute"
  instance_depends_on                         = [module.cloud_networking.subnet, local_file.cloud_group_vars]
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
  secgroup_name                               = "${var.cluster_name}_sg"
  network_name                                = "${var.cluster_name}_network"
  instance_user                               = var.instance_user
  ssh_key_file                                = var.ssh_key_file
  floatingip_pool                             = var.floatingip_pool
}

# Run Ansible
resource "null_resource" "ansible_master" {
  count = var.master_count
  triggers = {
    master_instance_id = module.cloud_master.instances[count.index].id
  }

  provisioner "remote-exec" {
    inline = ["#Connected"]

    connection {
      user        = var.instance_user
      host        = module.cloud_master.instances[count.index].floating_ip
      private_key = file(var.ssh_key_file)
      agent       = "true"
    }
  }

  provisioner "local-exec" {
    command = <<EOT
    cd ansible;
    ansible-playbook -i cloud_hosts.ini master.yml
    EOT
  }
}

resource "null_resource" "ansible_worker" {
  count = var.worker_count
  triggers = {
    worker_instance_id = module.cloud_worker.instances[count.index].id
  }

  provisioner "remote-exec" {
    inline = ["#Connected"]

    connection {
      user        = var.instance_user
      host        = module.cloud_worker.instances[count.index].floating_ip
      private_key = file(var.ssh_key_file)
      agent       = "true"
    }
  }

  provisioner "local-exec" {
    command = <<EOT
    cd ansible;
    ansible-playbook -i cloud_hosts.ini worker.yml
    EOT
  }
}

#--------------------------------------------------------------------------------------------------------------------------

# # Edge Cluster

# data "template_file" "group_vars_edge" {
#   template = "${file("./group_vars.tpl")}"
#   vars = {
#     subnet_cidr = "10.0.1.0/24"
#   }
# }

# resource "local_file" "group_vars_edge" {
#   content  = data.template_file.group_vars_edge.rendered
#   filename = "./ansible/group_vars/edge"
# }

# # Create the network
# module "edge_networking" {
#   source               = "./modules/networking"
#   floatingip_pool      = var.floatingip_pool
#   private_network_name = "edge_network"
#   subnet_name          = "edge_subnet"
#   subnet_cidr          = "10.0.1.0/24"
#   public_network_name  = var.public_network_name
#   router_name          = "edge_router"
#   secgroup_name        = "edge_sg"
#   secgroup_description = var.secgroup_description
#   secgroup_rules       = var.secgroup_rules

# }

# # Create the compute instance
# module "edge_compute" {
#   source                                      = "./modules/compute"
#   instance_depends_on                         = [module.edge_networking.subnet, module.edge_networking.floatingip_address, local_file.group_vars_edge]
#   cluster_name                                = "edge"
#   instance_image_id                           = var.instance_image_id
#   instance_flavor_name                        = "lrz.medium"
#   instance_keypair_name                       = var.instance_keypair_name
#   instance_availability_zone                  = var.instance_availability_zone
#   instance_block_device_source_type           = var.instance_block_device_source_type
#   instance_block_device_volume_size           = var.instance_block_device_volume_size
#   instance_block_device_boot_index            = var.instance_block_device_boot_index
#   instance_block_device_destination_type      = var.instance_block_device_destination_type
#   instance_block_device_delete_on_termination = var.instance_block_device_delete_on_termination
#   secgroup_name                               = "edge_sg"
#   network_name                                = "edge_network"
#   floatingip_address                          = module.edge_networking.floatingip_address
#   instance_user                               = var.instance_user
#   ssh_key_file                                = var.ssh_key_file
# }
