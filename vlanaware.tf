##VLAN AWARE VM CREATION SCRIPT##
###########################################
#######     GENERAL ITEMS   ###############
###########################################
#Creating KEY-PAIR for SSH
resource "openstack_compute_keypair_v2" "ssh-key" {
  name = "ssh-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgR8LqMUAHATFZMbeyo4OobarANGKq+EtNNdmI2aunpM8vUR56xqi9Wp4I2PmYCJb+EOAmK9+hAnPOBHeCP1N5Xtmi3yastQKIFuQM3A6ZUNP5g0CLVdYCwUmLfzPw7nsBfBeFKU1qkKe39+7Kfoal/pTyhX9HcXS2NiMs/1PVsLcVcnKnqP2R0peQ1c3uhgMI0GJ4OhLB6AVXKAf/hmkEug8GY4SVup5YL2kIHaC1QGY5rFMMzgkEnp3uIBQzMGLZ/0zRDINiAJsXOMSWcOv4xyn1cqKdAr/MRh00ABo45XzsvsSm/DiyjfhC6jP2w7keleS0bikTGWfqEccXBCxN osp_admin@director.r60.lab"
}
##############################################
#######     NETWORKING ITEMS   ###############
##############################################
##############################################
#######     NETWORKING ITEMS   ###############
##############################################
# This will Create a ROUTER NAMED terraform_router and the resource name will be router_1
# External network id is for PUBLIC NETWORK
###############################################################################
###############################################################################
####################        PUBLIC NETWORK            #########################
###############################################################################
###############################################################################
resource "openstack_networking_network_v2" "public" {                       ###
  name           = "public"                                                 ###
  admin_state_up = true                                                     ###
  external = true                                                           ###
  segments {                                                                ###
    segmentation_id   = "604"                                               ###
    network_type      = "vlan"                                              ###
    physical_network  = "physext"                                           ###
  }                                                                         ###
}                                                                           ###
###############################################################################
###############################################################################
####################        PUBLIC SUB-NETWORK            #####################
###############################################################################
###############################################################################
resource "openstack_networking_subnet_v2" "external_subnet" {               ###
  name       = "external_subnet"                                            ###
  network_id = openstack_networking_network_v2.public.id                    ###
  cidr       = "100.67.60.192/26"                                           ###
  gateway_ip = "100.67.60.193"                                              ###
  allocation_pool {                                                         ###
    end = "100.67.60.240"                                                   ###
    start = "100.67.60.194"                                                 ###
  }                                                                         ###
  enable_dhcp = false                                                       ###
}                                                                           ###
###############################################################################
###############################################################################
data "openstack_networking_network_v2" "network" {
  depends_on = [openstack_networking_network_v2.public,]
  name = "public"
}
# This will Create a ROUTER NAMED terraform_router and the resource name will be router_1
# External network id is for PUBLIC NETWORK
################
###   ROUTER ###
################
resource "openstack_networking_router_v2" "router_1" {
  name                = "router_1"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.network.id #"84b632fa-6721-4ce8-98c0-3a2df535f941"#openstack_networking_network_v2.public.id
}
################
###  NETWORK ###
################
# PARENT Network Resource Creation
resource "openstack_networking_network_v2" "parent_network" {
  name = "parent_network"
//  admin_state_up = "true"
  segments {
    segmentation_id   = "221"
    network_type = "vlan"
    physical_network = "physint"
  }
}
# SUB Network Resource Creation
resource "openstack_networking_network_v2" "sub_network" {
  name = "sub_network"
//  admin_state_up = "true"
  segments {
    segmentation_id   = "220"
    network_type = "vlan"
    physical_network = "physint"
  }
}
################
###SUBNETWORK###
################
# Creating PARENT Subnet for PARENT Network
resource "openstack_networking_subnet_v2" "parent_subnet" {
  name       = "parent_subnet"
  network_id = openstack_networking_network_v2.parent_network.id
  cidr       = "192.168.70.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}
# Creating Subnet for SUB Network
resource "openstack_networking_subnet_v2" "sub_subnet" {
  name       = "sub_subnet"
  network_id = openstack_networking_network_v2.sub_network.id
  cidr       = "192.168.90.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}
################
###   PORTS  ###
################
#Creating Port parent
resource "openstack_networking_port_v2" "parent_port" {
  depends_on = [openstack_networking_subnet_v2.parent_subnet,]

  name           = "parent_port"
  network_id     = openstack_networking_network_v2.parent_network.id
//  admin_state_up = "true"

    fixed_ip {
    subnet_id  =  openstack_networking_subnet_v2.parent_subnet.id
    ip_address = "192.168.70.10"
  }
}
#Creating Sub port
resource "openstack_networking_port_v2" "sub_port" {
  depends_on = [openstack_networking_subnet_v2.sub_subnet,]

  name           = "sub_port"
  network_id     = openstack_networking_network_v2.sub_network.id
//  admin_state_up = "true"
  mac_address = openstack_networking_port_v2.parent_port.mac_address
    fixed_ip {
    subnet_id  =  openstack_networking_subnet_v2.sub_subnet.id
    ip_address = "192.168.90.10"
  }
}
#Creating Sub Port for simple vm on Sub network
resource "openstack_networking_port_v2" "sub_port_simple" {
  depends_on = [openstack_networking_subnet_v2.sub_subnet,]

  name           = "sub_port_simple"
  network_id     = openstack_networking_network_v2.sub_network.id
//  admin_state_up = "true"

    fixed_ip {
    subnet_id  =  openstack_networking_subnet_v2.sub_subnet.id
    ip_address = "192.168.90.11"
  }
}
####################
###SUBNET->ROUTER###
####################
resource "openstack_networking_router_interface_v2" "parent_router_interface" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = openstack_networking_subnet_v2.parent_subnet.id
}
resource "openstack_networking_router_interface_v2" "sub_router_interface" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = openstack_networking_subnet_v2.sub_subnet.id
}
######################
###VLANAWARE->TRUNK###
######################
resource "openstack_networking_trunk_v2" "trunk_1" {
  name           = "trunk_1"
//  admin_state_up = "true"
  port_id        = openstack_networking_port_v2.parent_port.id

  sub_port {
    port_id           = openstack_networking_port_v2.sub_port.id
    segmentation_id   = 220
    segmentation_type = "vlan"
  }
}
######################
###   FLOATING IP  ###
######################
#Creating floating ip
resource "openstack_networking_floatingip_v2" "vlan_floatip" {
  pool = data.openstack_networking_network_v2.network.name
}
resource "openstack_networking_floatingip_v2" "subnetwork_floatip" {
  pool = data.openstack_networking_network_v2.network.name
}
###########################################
#######     COMPUTE ITEMS   ###############
###########################################
######################################################
#######  VLAN AWARE INSTANCE CREATION   ##############
######################################################
resource "openstack_compute_instance_v2" "vlanaware_instance_1" {
  name            = "vlanaware_instance_1"
  security_groups = ["default"]
  image_name	= var.IMAGE_NAME
  flavor_name	= var.FLAVOR_NAME
  key_pair	= var.SSH_KEY_NAME
//  availability_zone = lookup(var.ZONE, var.AVAILABILITY_ZONES)
  availability_zone = data.openstack_compute_availability_zones_v2.zones.names.0
  network {
    port = openstack_networking_trunk_v2.trunk_1.port_id
  }
}
###########################################
####### FLOATING IP -> INSTANCE   #########
###########################################
resource "openstack_compute_floatingip_associate_v2" "vlan_floatip" {
  floating_ip = openstack_networking_floatingip_v2.vlan_floatip.address
  instance_id = openstack_compute_instance_v2.vlanaware_instance_1.id
  wait_until_associated = "true"

//    provisioner "local-exec" {
//    command = "echo private_ip: ${openstack_compute_instance_v2.instance_2.access_ip_v4} \n public_ip:  ${openstack_networking_floatingip_v2.floatip_2.address}"
//  }
  connection {
      user     = var.SSH_USER_NAME
      host     = openstack_networking_floatingip_v2.vlan_floatip.address
      private_key = file(var.SSH_KEY_FILE)
    }

  provisioner "file"{
      source = "/home/osp_admin/OpenForm/ifcfg-eth0.220"
      destination = "/home/centos/ifcfg-eth0.220"
  }
  provisioner "file"{
      source = "/home/osp_admin/OpenForm/router-eth0.220"
      destination = "/home/centos/router-eth0.220"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/centos/ifcfg-eth0.220 /etc/sysconfig/network-scripts/ifcfg-eth0.220",
      "sudo cp /home/centos/router-eth0.220 /etc/sysconfig/network-scripts/route-eth0.220",
      "sudo ls -l /etc/sysconfig/network-scripts/",
      "sudo systemctl restart network",
      "sudo ifconfig",
      "sudo ls -l /etc/sysconfig/network-scripts/",
      "sudo cat /etc/sysconfig/network-scripts/ifcfg-eth0.220",
      "sudo cat /etc/sysconfig/network-scripts/route-eth0.220",
      "sudo ifup /etc/sysconfig/network-scripts/ifcfg-eth0.220",
      "sudo ifconfig",
      "ping -c 10 8.8.8.8",
      "ping -c 10 -I eth0.220 192.168.90.11"
    ]
}
}
######################################################
#######  SIMPLE SUB INSTANCE CREATION   ##############
######################################################
resource "openstack_compute_instance_v2" "subnetwork_instance_1" {
  name            = "subnetwork_instance_1"
  security_groups = ["default"]
  image_name	= var.IMAGE_NAME
  flavor_name	= var.FLAVOR_NAME
  key_pair	= var.SSH_KEY_NAME
//  availability_zone = lookup(var.ZONE, var.AVAILABILITY_ZONES)
  availability_zone = data.openstack_compute_availability_zones_v2.zones.names.1
  network {
    port = openstack_networking_port_v2.sub_port_simple.id
  }
}
###########################################
####### FLOATING IP -> INSTANCE   #########
###########################################
resource "openstack_compute_floatingip_associate_v2" "subnetwork_floatip" {
  floating_ip = openstack_networking_floatingip_v2.subnetwork_floatip.address
  instance_id = openstack_compute_instance_v2.subnetwork_instance_1.id
  wait_until_associated = "true"
  depends_on = [openstack_compute_floatingip_associate_v2.vlan_floatip,]
//    provisioner "local-exec" {
//    command = "echo private_ip: ${openstack_compute_instance_v2.instance_2.access_ip_v4} \n public_ip:  ${openstack_networking_floatingip_v2.floatip_2.address}"
//  }
  connection {
      user     = var.SSH_USER_NAME
      host     = openstack_networking_floatingip_v2.subnetwork_floatip.address
      private_key = file(var.SSH_KEY_FILE)
    }
  provisioner "remote-exec" {
    inline = [
      "sudo ifconfig",
      "ping -c 5 8.8.8.8",
      "ping -c 10 192.168.90.10"
    ]
}
}
###########################################
#######     OUTPUT ITEMS   ################
###########################################
output "vlanaware_instance_private_ip"{
  value = openstack_compute_instance_v2.vlanaware_instance_1.access_ip_v4
}
output "subnet_instance_private_ip"{
  value = openstack_compute_instance_v2.subnetwork_instance_1.access_ip_v4
}
output "vlanaware_instance_public_ip"{
  value = openstack_networking_floatingip_v2.vlan_floatip.address
}
output "subnet_instance_public_ip"{
  value = openstack_networking_floatingip_v2.subnetwork_floatip.address
}