variable "cluster_name" {
  type    = string
  default = "cloud"
}

# Network variables

variable "floatingip_pool" {
  type    = string
  default = "internet_pool"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "public_network_name" {
  type    = string
  default = "internet_pool"
}

variable "secgroup_name" {
  type    = string
  default = "k8s"
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
    { "cidr" = "0.0.0.0/0", "ip_protocol" = "tcp", "port" = 31001 }
  ]
}

# Compute Variables

variable "master_count" {
  type    = number
  default = 1
}

variable "worker_count" {
  type    = number
  default = 1
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

variable "instance_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_key_file" {
  type    = string
  default = "~/.ssh/thesis-lrz"
}

