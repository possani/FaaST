# Create network
resource "openstack_networking_network_v2" "private_network" {
  name                  = var.private_network_name
  admin_state_up        = "true"
  port_security_enabled = "true"
}

# Create subnet
resource "openstack_networking_subnet_v2" "subnet" {
  name       = var.subnet_name
  cidr       = var.subnet_cidr
  network_id = openstack_networking_network_v2.private_network.id
  ip_version = 4
}

# Get public network info
data "openstack_networking_network_v2" "public_network" {
  name = var.public_network_name
}

# Create a router
resource "openstack_networking_router_v2" "router" {
  name                = var.router_name
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public_network.id
}

# Give internet access to the subnet
resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

# Create a Secutiry Group for k8s
resource "openstack_networking_secgroup_v2" "secgroup" {
  name        = var.secgroup_name
  description = var.secgroup_description
}

# Create a Secutiry Group Rules for k8s
resource "openstack_networking_secgroup_rule_v2" "secgroup_rules" {
  count = length(var.secgroup_rules)

  direction = "ingress"
  ethertype = "IPv4"

  protocol          = var.secgroup_rules[count.index].ip_protocol
  port_range_min    = var.secgroup_rules[count.index].port
  port_range_max    = var.secgroup_rules[count.index].port
  remote_ip_prefix  = var.secgroup_rules[count.index].cidr
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

#  Load Balancer
resource "openstack_lb_loadbalancer_v2" "lb_svc" {
  name          = "lb_svc"
  vip_subnet_id = openstack_networking_subnet_v2.subnet.id
}

resource "openstack_networking_floatingip_v2" "lb_floatingip_svc" {
  pool       = var.floatingip_pool
  port_id    = openstack_lb_loadbalancer_v2.lb_svc.vip_port_id
  depends_on = [openstack_networking_router_interface_v2.router_interface]
}

resource "openstack_lb_pool_v2" "pool_svc" {
  name            = "pool_svc"
  protocol        = "HTTP"
  lb_method       = "ROUND_ROBIN"
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_svc.id
}

resource "openstack_lb_listener_v2" "listener_svc" {
  name            = "listener_svc"
  protocol        = "HTTP"
  protocol_port   = 80
  default_pool_id = openstack_lb_pool_v2.pool_svc.id
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_svc.id
}

resource "openstack_lb_monitor_v2" "monitor_svc" {
  pool_id     = openstack_lb_pool_v2.pool_svc.id
  type        = "TCP"
  delay       = 20
  timeout     = 10
  max_retries = 5
}
