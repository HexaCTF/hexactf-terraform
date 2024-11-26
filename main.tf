resource "openstack_compute_keypair_v2" "nfs_keypair" {
  name       = "storage-nfs-keypair"
  public_key = file(var.public_key_name)

}

# Get the existing public network
data "openstack_networking_network_v2" "public_network" {
  name = var.public_network_name
}

# Get the existing public router
data "openstack_networking_router_v2" "public_router" {
  name = var.public_router_name
}

# Create the storage network
resource "openstack_networking_network_v2" "storage_network" {
  name = var.storage_network_name
}

# Create the storage subnet
resource "openstack_networking_subnet_v2" "storage_subnet" {
  name            = var.storage_subnet_name
  network_id      = openstack_networking_network_v2.storage_network.id
  cidr            = var.storage_subnet_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
}

# Connect the storage subnet to the public router
resource "openstack_networking_router_interface_v2" "storage_router_interface" {
  router_id = data.openstack_networking_router_v2.public_router.id
  subnet_id = openstack_networking_subnet_v2.storage_subnet.id
}

# Create the NFS security group
resource "openstack_networking_secgroup_v2" "nfs_secgroup" {
  name        = "${var.storage_instance_name}-nfs-secgroup"
  description = "Security group for NFS access"
}

# Allow NFS (TCP and UDP port 2049) ingress
resource "openstack_networking_secgroup_rule_v2" "nfs_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2049
  port_range_max    = 2049
  remote_ip_prefix  = "10.0.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.nfs_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "nfs_ingress_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 2049
  port_range_max    = 2049
  remote_ip_prefix  = "10.0.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.nfs_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "nfs_rpc_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 111
  port_range_max    = 111
  remote_ip_prefix  = "10.0.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.nfs_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "nfs_rpc_ingress_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 111
  port_range_max    = 111
  remote_ip_prefix  = "10.0.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.nfs_secgroup.id
}

# Allow SSH ingress (optional)
resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.nfs_secgroup.id
}

# Allow ICMP ingress (optional)
resource "openstack_networking_secgroup_rule_v2" "icmp_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  security_group_id = openstack_networking_secgroup_v2.nfs_secgroup.id
}

# Create a port in the storage network for the instance
resource "openstack_networking_port_v2" "storage_port" {
  name               = "${var.storage_instance_name}-port"
  network_id         = openstack_networking_network_v2.storage_network.id
  security_group_ids = [openstack_networking_secgroup_v2.nfs_secgroup.id]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.storage_subnet.id
  }
}

# Create a floating IP for the storage instance
resource "openstack_networking_floatingip_v2" "storage_fip" {
  pool = var.public_network_name
}

# Associate the floating IP with the storage instance's port
resource "openstack_networking_floatingip_associate_v2" "storage_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.storage_fip.address
  port_id     = openstack_networking_port_v2.storage_port.id
}

resource "openstack_blockstorage_volume_v3" "nfs-volume" {
  name = "bfs-volume"
  size = 50
}

# Create the storage instance
resource "openstack_compute_instance_v2" "storage_instance" {
  name            = var.storage_instance_name
  flavor_name     = var.storage_flavor_name
  image_name      = var.storage_image_name
  key_pair        = openstack_compute_keypair_v2.nfs_keypair.name
  security_groups = [openstack_networking_secgroup_v2.nfs_secgroup.name]

  network {
    port = openstack_networking_port_v2.storage_port.id
  }

  metadata = {
    ssh_user = "ubuntu"
  }
}

resource "openstack_compute_volume_attach_v2" "nfs-volume-attached" {
  instance_id = openstack_compute_instance_v2.storage_instance.id
  volume_id   = openstack_blockstorage_volume_v3.nfs-volume.id
}

# --------------- Kubernetes Router -------------------
resource "openstack_networking_router_v2" "kubernetes_router" {
  name = "kubernetes-router"
}

data "openstack_networking_network_v2" "kubernetes_network" {
  name = "hexactf-cluster-network"
}

data "openstack_networking_subnet_v2" "kubernetes_subnet" {
  name = "hexactf-internal-network"
}

resource "openstack_networking_port_v2" "kubernetes_router_port" {
  name           = "kubernetes-storage-port"
  network_id     = data.openstack_networking_network_v2.kubernetes_network.id
  admin_state_up = "true"

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.kubernetes_subnet.id
    ip_address = "10.0.10.20"
  }
}

resource "openstack_networking_router_interface_v2" "kubernetes_interface" {
  router_id = openstack_networking_router_v2.kubernetes_router.id
  port_id   = openstack_networking_port_v2.kubernetes_router_port.id
}

resource "openstack_networking_port_v2" "storage_kubernetes_router_port" {
  name           = "kubernetes-storage-port"
  network_id     = openstack_networking_network_v2.storage_network.id
  admin_state_up = "true"

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.storage_subnet.id
    ip_address = "10.0.50.20"
  }
}

resource "openstack_networking_router_interface_v2" "storage_kubernetes_interface" {
  router_id = openstack_networking_router_v2.kubernetes_router.id
  port_id   = openstack_networking_port_v2.storage_kubernetes_router_port.id
}

# ----------- Devops Harbor -----------
# ------------- Network ---------------
# Create the devops network
resource "openstack_networking_network_v2" "devops_network" {
  name = var.devops_network_name
}

# Create the devops subnet
resource "openstack_networking_subnet_v2" "devops_subnet" {
  name            = var.devops_subnet_name
  network_id      = openstack_networking_network_v2.devops_network.id
  cidr            = var.devops_subnet_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
}

# Connect the devops subnet to the public router
resource "openstack_networking_router_interface_v2" "devops_router_interface" {
  router_id = data.openstack_networking_router_v2.public_router.id
  subnet_id = openstack_networking_subnet_v2.devops_subnet.id
}


# -------------- devops -------------------
resource "openstack_compute_keypair_v2" "devops_keypair" {
  name       = "devops-keypair"
  public_key = file(var.devops_public_key_path)
}

# Create the devops security group
resource "openstack_networking_secgroup_v2" "devops_secgroup" {
  name        = "${var.devops_instance_name}-secgroup"
  description = "Security group for devops access"
}

resource "openstack_networking_secgroup_rule_v2" "devops_secgroup_rules" {
  count             = length(var.devops_allowed_ports)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = lookup(var.devops_allowed_ports[count.index], "protocol", "tcp")
  port_range_min    = lookup(var.devops_allowed_ports[count.index], "port_range_min")
  port_range_max    = lookup(var.devops_allowed_ports[count.index], "port_range_max")
  remote_ip_prefix  = lookup(var.devops_allowed_ports[count.index], "remote_ip_prefix", "0.0.0.0/0")
  security_group_id = openstack_networking_secgroup_v2.devops_secgroup.id
}



# Create a port in the devops network for the instance
resource "openstack_networking_port_v2" "devops_port" {
  name               = "${var.devops_instance_name}-port"
  network_id         = openstack_networking_network_v2.devops_network.id
  security_group_ids = [openstack_networking_secgroup_v2.devops_secgroup.id]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.devops_subnet.id
  }
}

# Create a floating IP for the devops instance
resource "openstack_networking_floatingip_v2" "devops_fip" {
  pool = var.public_network_name
}

# Associate the floating IP with the devops instance's port
resource "openstack_networking_floatingip_associate_v2" "devops_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.devops_fip.address
  port_id     = openstack_networking_port_v2.devops_port.id
}

resource "openstack_blockstorage_volume_v3" "devops_volume" {
  name = "devops-volume"
  size = 20
}

# Create the devops instance
resource "openstack_compute_instance_v2" "devops_instance" {
  name            = var.devops_instance_name
  flavor_name     = var.devops_flavor_name
  image_name      = var.devops_image_name
  key_pair        = openstack_compute_keypair_v2.devops_keypair.name
  security_groups = [openstack_networking_secgroup_v2.devops_secgroup.name]

  network {
    port = openstack_networking_port_v2.devops_port.id
  }

  metadata = {
    ssh_user = "ubuntu"
  }
}

resource "openstack_compute_volume_attach_v2" "devops-volume-attached" {
  instance_id = openstack_compute_instance_v2.devops_instance.id
  volume_id   = openstack_blockstorage_volume_v3.devops_volume.id
}

# --------------- Kubernetes Router -------------------

resource "openstack_networking_port_v2" "devops_kubernetes_router_port" {
  name           = "kubernetes-devops-port"
  network_id     = openstack_networking_network_v2.devops_network.id
  admin_state_up = "true"

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.devops_subnet.id
    ip_address = var.devops_port_address
  }
}

resource "openstack_networking_router_interface_v2" "devops_kubernetes_interface" {
  router_id = openstack_networking_router_v2.kubernetes_router.id
  port_id   = openstack_networking_port_v2.devops_kubernetes_router_port.id
}
