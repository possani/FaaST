variable "cluster_name" {
  type    = string
  default = "cloud"
}

# Network variables

variable "floatingip_pool" {
  type    = string
  default = "internet_pool"
}

variable "public_network_name" {
  type    = string
  default = "internet_pool"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
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

variable "instance_block_device_volume_size" {
  type    = number
  default = 20
}

variable "ssh_key_file" {
  type    = string
  default = "~/.ssh/thesis-lrz"
}

