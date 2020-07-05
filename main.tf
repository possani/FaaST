# Configure the OpenStack provider
provider "openstack" {
  cloud = "openstack"
}

# Cloud cluster
module "cloud_cluster" {
  source                            = "./modules/cluster"
  cluster_name                      = var.cluster_name
  worker_count                      = var.worker_count
  master_count                      = var.master_count
  instance_image_id                 = var.instance_image_id
  instance_flavor_name              = var.instance_flavor_name
  instance_keypair_name             = var.instance_keypair_name
  instance_block_device_volume_size = var.instance_block_device_volume_size
  ssh_key_file                      = var.ssh_key_file
  floatingip_pool                   = var.floatingip_pool
  public_network_name               = var.public_network_name
  subnet_cidr                       = var.subnet_cidr
}

module "edge_cluster" {
  source                            = "./modules/cluster"
  cluster_name                      = "edge"
  worker_count                      = var.worker_count
  master_count                      = var.master_count
  instance_image_id                 = var.instance_image_id
  instance_flavor_name              = var.instance_flavor_name
  instance_keypair_name             = var.instance_keypair_name
  instance_block_device_volume_size = var.instance_block_device_volume_size
  ssh_key_file                      = var.ssh_key_file
  floatingip_pool                   = var.floatingip_pool
  public_network_name               = var.public_network_name
  subnet_cidr                       = "10.0.0.1/24"
}
