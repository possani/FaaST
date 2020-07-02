# Configure the OpenStack provider
provider "openstack" {
  cloud = "openstack"
}

# Cloud Cluster
data "template_file" "group_vars_cloud" {
  template = "${file("./group_vars.tpl")}"
  vars = {
    subnet_cidr = var.subnet_cidr
    cluster_name = var.cluster_name
  }
}

resource "local_file" "group_vars_cloud" {
  content  = data.template_file.group_vars_cloud.rendered
  filename = "./ansible/group_vars/cloud"
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
  instance_depends_on                         = [module.cloud_networking.subnet, local_file.group_vars_cloud]
  cluster_name                                = var.cluster_name
  instance_role                               = "master"
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
  floatingip_pool      = var.floatingip_pool
}

module "cloud_worker" {
  source                                      = "./modules/compute"
  instance_depends_on                         = [module.cloud_networking.subnet, local_file.group_vars_cloud]
  cluster_name                                = var.cluster_name
  instance_role                               = "worker"
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
  floatingip_pool      = var.floatingip_pool
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
