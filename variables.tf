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

variable "public_key_name" {
  description = "Name of the key pair to use for the instance"
}

variable "nfs_allowed_cidr" {
  description = "CIDR range allowed to access NFS (e.g., client network)"
  default     = "0.0.0.0/0"
}

# --------------- Devops -------------
# Network Variables
variable "devops_network_name" {
  description = "Name of the DevOps network"
}

variable "devops_subnet_name" {
  description = "Name of the DevOps subnet"
}

variable "devops_subnet_cidr" {
  description = "CIDR block for the DevOps subnet"
}


# DevOps Keypair Variables
variable "devops_public_key_path" {
  description = "Path to the public key for the DevOps keypair"
}

# devops Instance Variables
variable "devops_instance_name" {}

variable "devops_flavor_name" {
  description = "Flavor name for the devops instance"
}

variable "devops_allowed_ports" {
  description = "List of allowed ports for the devops security group"
  type = list(object({
    protocol         = string
    port_range_min   = number
    port_range_max   = number
    remote_ip_prefix = string
  }))
}

# Harbor Instance Variables
# variable "harbor_instance_name" {
#   description = "Name of the Harbor instance"
#   type        = string
# }

# variable "harbor_flavor_name" {
#   description = "Flavor name for the Harbor instance"
#   type        = string
# }

# variable "harbor_allowed_ports" {
#   description = "List of allowed ports for the Harbor security group"
#   type = list(object({
#     protocol         = string
#     port_range_min   = number
#     port_range_max   = number
#     remote_ip_prefix = string
#   }))
# }

# # Shared Variables
variable "devops_image_name" {
  description = "Image name to use for DevOps instances"
  type        = string
}

variable "devops_port_address" {
  description = "Fixed IP address for the Kubernetes router port in the DevOps network"
  type        = string
}

# Defaults for optional fields
variable "default_allowed_ports" {
  description = "Default allowed ports for security groups (HTTP, HTTPS, SSH, ICMP)"
  default = [
    {
      protocol         = "tcp"
      port_range_min   = 22
      port_range_max   = 22
      remote_ip_prefix = "0.0.0.0/0"
    },
    {
      protocol         = "tcp"
      port_range_min   = 80
      port_range_max   = 80
      remote_ip_prefix = "0.0.0.0/0"
    },
    {
      protocol         = "tcp"
      port_range_min   = 443
      port_range_max   = 443
      remote_ip_prefix = "0.0.0.0/0"
    },
    {
      protocol         = "icmp"
      port_range_min   = 0
      port_range_max   = -1
      remote_ip_prefix = "0.0.0.0/0"
    }
  ]
}
