data "openstack_networking_network_v2" "ext_net" {
  name     = "Ext-Net"
  region   = var.region
  external = true
}

resource "openstack_networking_network_v2" "private" {
  name           = var.network_name
  region         = var.region
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "private" {
  name            = "${var.network_name}-subnet"
  region          = var.region
  network_id      = openstack_networking_network_v2.private.id
  cidr            = var.subnet_cidr
  ip_version      = 4
  dns_nameservers = ["213.186.33.99"]
  enable_dhcp     = true

  allocation_pool {
    start = cidrhost(var.subnet_cidr, 10)
    end   = cidrhost(var.subnet_cidr, 254)
  }
}

resource "openstack_networking_router_v2" "router" {
  name                = "${var.network_name}-router"
  region              = var.region
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.ext_net.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  region    = var.region
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.private.id
}
