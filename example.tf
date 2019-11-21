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
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

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


# Adding Subnet to the Router Interface
resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

#Creating floating ip
resource "openstack_networking_floatingip_v2" "floatip_1" {
  pool = "public"
}


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

#Creating Resource for floating ip
resource "openstack_compute_floatingip_associate_v2" "floatip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.floatip_1.address}"
  instance_id = "${openstack_compute_instance_v2.instance_1.id}"



  #Creation a SSH Connection to Access VM and Perform a test in Created VM
    connection {
      user     = "${var.SSH_USER_NAME}"
      host     = "${openstack_networking_floatingip_v2.floatip_1.address}"
      private_key = "${file(var.SSH_KEY_FILE)}"
    }

 provisioner "remote-exec" {
    inline = [
      "echo terraform executed > /tmp/foo",
      "pwd",
      "sudo yum -y update",
      "sudo yum -y install nginx",
      "sudo systemctl start nginx",
      "sudo systemctl status nginx",
    ]
}
}


