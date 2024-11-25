variable "auth_url" {
  description = "OpenStack authentication URL"
}

variable "user_name" {
  description = "OpenStack user name"
}

variable "password" {
  description = "OpenStack user password"
  sensitive   = true
}

variable "tenant_name" {
  description = "OpenStack tenant name"
}

variable "region" {
  description = "OpenStack region"
}

variable "public_network_name" {
  description = "Name of the existing public network"
}

variable "public_router_name" {
  description = "Name of the existing public router"
}

variable "storage_network_name" {
  description = "Name of the storage network to create"
}

variable "storage_subnet_name" {
  description = "Name of the storage subnet to create"
}

variable "storage_subnet_cidr" {
  description = "CIDR block for the storage subnet"
}

variable "dns_nameservers" {
  description = "List of DNS nameservers for the storage subnet"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "storage_instance_name" {
  description = "Name of the storage instance"
}

variable "storage_flavor_name" {
  description = "Flavor name for the storage instance"
}

variable "storage_image_name" {
  description = "Image name for the storage instance"
}

variable "key_pair_name" {
  description = "Name of the key pair to use for the instance"
}
