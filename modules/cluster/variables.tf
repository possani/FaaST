variable "cluster_name" {
  type = string
}

# Network variables

variable "floatingip_pool" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "pod_subnet" {
  type = string
}

variable "public_network_name" {
  type = string
}

variable "secgroup_description" {
  type    = string
  default = "k8s security group description"
}

variable "secgroup_rules" {
  type = list
  default = [
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 22 },
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 6443 },
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 80 },
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 443 },
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 31001 },
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 31002 },
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 31003 },
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 31004 }
  ]
}

# Compute Variables

variable "master_count" {
  type = number
}

variable "worker_count" {
  type = number
}

variable "instance_image_id" {
  type = string
}

variable "instance_flavor_name" {
  type = string
}

variable "instance_keypair_name" {
  type = string
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
  type = number
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

variable "instance_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_key_file" {
  type = string
}

