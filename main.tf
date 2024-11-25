# Get the existing public network
data "openstack_networking_network_v2" "public_network" {
  name = var.public_network_name
}

# Get the existing public router
data "openstack_networking_router_v2" "public_router" {
  name = var.public_router_name
}

# Ensure the public router has an external gateway to the public network
resource "openstack_networking_router_v2" "public_router_gateway" {
  router_id = data.openstack_networking_router_v2.public_router.id

  external_gateway {
    network_id = data.openstack_networking_network_v2.public_network.id
  }
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

# Create a port in the storage network for the instance
resource "openstack_networking_port_v2" "storage_port" {
  name       = "${var.storage_instance_name}-port"
  network_id = openstack_networking_network_v2.storage_network.id
}

# Create a floating IP for the storage instance
resource "openstack_networking_floatingip_v2" "storage_fip" {
  pool = var.public_network_name
}

# Associate the floating IP with the storage instance's port
resource "openstack_networking_floatingip_associate_v2" "storage_fip_assoc" {
  floatingip_id = openstack_networking_floatingip_v2.storage_fip.id
  port_id       = openstack_networking_port_v2.storage_port.id
}

# Create the storage instance
resource "openstack_compute_instance_v2" "storage_instance" {
  name        = var.storage_instance_name
  flavor_name = var.storage_flavor_name
  image_name  = var.storage_image_name
  key_pair    = var.key_pair_name

  network {
    port = openstack_networking_port_v2.storage_port.id
  }
}
