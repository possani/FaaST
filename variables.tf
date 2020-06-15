variable "floatingip_pool" {
  type    = string
  default = "internet_pool"
}

## Instance Variables

variable "instance_name" {
  type    = string
  default = "k8smaster"
}

variable "instance_image_id" {
  type    = string
  default = "0d006427-aef5-4ed8-99c6-e381724a60e0"
}

variable "instance_flavor_name" {
  type    = string
  default = "lrz.medium"
}

variable "instance_keypair_name" {
  type        = string
  default     = "thesis-lrz"
  description = "SSH keypair name"
}

variable "instance_availability_zone" {
  type    = string
  default = "nova"
}

variable "instance_block_device_source_type" {
  type    = string
  default = "image"
}

variable "instance_block_device_volume_size" {
  type    = number
  default = 20
}

variable "instance_block_device_boot_index" {
  type    = number
  default = 0
}

variable "instance_block_device_destination_type" {
  type    = string
  default = "volume"
}

variable "instance_block_device_delete_on_termination" {
  type    = bool
  default = true
}

variable "instance_network" {
  type    = string
  default = "internet"
}

## Security Group Variables

variable "rke_secgroup_name" {
  type    = string
  default = "rke"
}

variable "rke_secgroup_description" {
  type    = string
  default = "rke security group description"
}

variable "rke_secgroup_rules" {
  type = list
  default = [
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 22 },
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 6443 },
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 80 },
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 443 }
  ]
}

## RKE Cloud Cluster Variables

variable "cloud_cluster_user" {
  type    = string
  default = "ubuntu"
}

variable "cloud_cluster_ssh_key" {
  type    = string
  default = "~/.ssh/thesis-lrz"
}

