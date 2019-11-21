# Configure the OpenStack Provider
# Authenticating the Openstack with Admin User Credentials

# This will Create a ROUTER NAMED terraform_router and the resource name will be router_1
# External network id is for PUBLIC NETWORK
resource "openstack_networking_router_v2" "router_1" {
  name                = "router_1"
  admin_state_up      = true
  external_network_id = "45d3d1ac-f2a8-4b69-85c0-e8cbfc7f3552"
}

# Network Resource Creation
resource "openstack_networking_network_v2" "network_1" {
  name              = "network_1"
  admin_state_up    = "true"
}
# Creating Subnet for Network
resource "openstack_networking_subnet_v2" "subnet_1" {
  name       = "subnet_1"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr       = "192.168.199.0/24"
  ip_version = 4
}
# Creating Security Group for Network
#resource "openstack_compute_secgroup_v2" "secgroup_1" {
#  name        = "secgroup_1"
#  description = "a security group"
#
 # rule {
  #  from_port   = 22
   # to_port     = 22
    #ip_protocol = "tcp"
   # cidr        = "0.0.0.0/0"
  #}
#}
# Creating Port for Network
resource "openstack_networking_port_v2" "port_1" {
  name               = "port_1"
  network_id         = "${openstack_networking_network_v2.network_1.id}"
  admin_state_up     = "true"
  #security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_1.id}"]

  fixed_ip {
    subnet_id  =  "${openstack_networking_subnet_v2.subnet_1.id}"
    ip_address = "192.168.199.10"
  }
}

#Creating a Keypair
#resource "openstack_compute_keypair_v2" "ssh-key" {
#  name = "ssh-key"
#}


# Creating Instance Resource
resource "openstack_compute_instance_v2" "instance_1" {
  name            = "instance_1"
  security_groups = ["default"]
  image_name	= "${var.IMAGE_NAME}"
  flavor_name	= "${var.FLAVOR_NAME}"
  key_pair	= "${var.SSH_KEY_NAME}"
  network {
    port = "${openstack_networking_port_v2.port_1.id}"
  }
}

# Adding Subnet to the Router Interface
resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

#Creating Floating IP Pool
resource "openstack_compute_floatingip_v2" "floatip_1" {
  pool = "public"
}
#Attaching floating ip to Instance
resource "openstack_compute_floatingip_associate_v2" "floatip_1" {
  floating_ip = "${openstack_compute_floatingip_v2.floatip_1.address}"
  instance_id = "${openstack_compute_instance_v2.instance_1.id}"
}
