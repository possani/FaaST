# Configure the OpenStack provider
provider "openstack" {
  cloud = "openstack"
}

# Create the network
module "cloud_networking" {
  source               = "./modules/networking"
  floatingip_pool      = var.floatingip_pool
  private_network_name = var.private_network_name
  subnet_name          = var.subnet_name
  subnet_cidr          = var.subnet_cidr
  public_network_name  = var.public_network_name
  router_name          = var.router_name
  secgroup_name        = var.secgroup_name
  secgroup_description = var.secgroup_description
  secgroup_rules       = var.secgroup_rules

}

# Create the compute instance
module "cloud_compute" {
  source                                      = "./modules/compute"
  instance_depends_on                         = [module.cloud_networking.subnet, module.cloud_networking.floatingip_address]
  instance_name                               = var.instance_name
  instance_image_id                           = var.instance_image_id
  instance_flavor_name                        = var.instance_flavor_name
  instance_keypair_name                       = var.instance_keypair_name
  instance_availability_zone                  = var.instance_availability_zone
  instance_block_device_source_type           = var.instance_block_device_source_type
  instance_block_device_volume_size           = var.instance_block_device_volume_size
  instance_block_device_boot_index            = var.instance_block_device_boot_index
  instance_block_device_destination_type      = var.instance_block_device_destination_type
  instance_block_device_delete_on_termination = var.instance_block_device_delete_on_termination
  secgroup_name                               = var.secgroup_name
  network_name                                = var.private_network_name
  floatingip_address                          = module.cloud_networking.floatingip_address
  instance_user                               = var.instance_user
  ssh_key_file                                = var.ssh_key_file
}
