# Configure the OpenStack Provider
# Authenticating the Openstack with Admin User Credentials

#Creating a Project
resource "openstack_identity_project_v3" "project_1" {
  name        = "project_1"
  description = "Terrraform Project Use Case as Example"
}

#Creating KEY-PAIR for SSH
resource "openstack_compute_keypair_v2" "ssh-key" {
  name = "ssh-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgR8LqMUAHATFZMbeyo4OobarANGKq+EtNNdmI2aunpM8vUR56xqi9Wp4I2PmYCJb+EOAmK9+hAnPOBHeCP1N5Xtmi3yastQKIFuQM3A6ZUNP5g0CLVdYCwUmLfzPw7nsBfBeFKU1qkKe39+7Kfoal/pTyhX9HcXS2NiMs/1PVsLcVcnKnqP2R0peQ1c3uhgMI0GJ4OhLB6AVXKAf/hmkEug8GY4SVup5YL2kIHaC1QGY5rFMMzgkEnp3uIBQzMGLZ/0zRDINiAJsXOMSWcOv4xyn1cqKdAr/MRh00ABo45XzsvsSm/DiyjfhC6jP2w7keleS0bikTGWfqEccXBCxN osp_admin@director.r60.lab"
}

#Creating Centos Images
resource "openstack_images_image_v2" "centos_1" {
  name             = "centos_1"
  image_source_url = "http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  container_format = "bare"
  disk_format      = "qcow2"
}

#Creating Flavor
resource "openstack_compute_flavor_v2" "flavor_1" {
  name  = "flavor_1"
  ram   = "8049"
  vcpus = "4"
  disk  = "50"
  is_public = true

  extra_specs = {
    "hw:cpu_policy"        = "dedicated",
    "hw:cpu_thread_policy" = "require",
    "hw:mem_page_size"     = "large",
    "hw:numa_node"         = "1"
  }
}

# This will Create a ROUTER NAMED terraform_router and the resource name will be router_1
# External network id is for PUBLIC NETWORK
resource "openstack_networking_router_v2" "router_1" {
  name                = "router_1"
  admin_state_up      = true
  external_network_id = "45d3d1ac-f2a8-4b69-85c0-e8cbfc7f3552"
}
###############################################################################################
# Network Resource Creation
resource "openstack_networking_network_v2" "network_1" {
  name = "network_1"
  admin_state_up = "true"
  segments {
    segmentation_id   = "219"
    network_type = "vlan"
    physical_network = "physint"
  }
}

# Creating Subnet for Network
resource "openstack_networking_subnet_v2" "subnet_1" {
  name       = "subnet_1"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr       = "192.168.199.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}
#################################################################################################
#######################VLAN AWARE VM NETWORK SCRIPTS#############################################
#================================================================================================
# PARENT Network Resource Creation
resource "openstack_networking_network_v2" "parent_network" {
  name = "parent_network"
  admin_state_up = "true"
  segments {
    segmentation_id   = "221"
    network_type = "vlan"
    physical_network = "physint"
  }
}

# Creating PARENT Subnet for PARENT Network
resource "openstack_networking_subnet_v2" "parent_subnet" {
  name       = "parent_subnet"
  network_id = "${openstack_networking_network_v2.parent_network.id}"
  cidr       = "192.168.70.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}
# SUB Network Resource Creation
resource "openstack_networking_network_v2" "sub_network" {
  name = "sub_network"
  admin_state_up = "true"
  segments {
    segmentation_id   = "220"
    network_type = "vlan"
    physical_network = "physint"
  }
}

# Creating Subnet for SUB Network
resource "openstack_networking_subnet_v2" "sub_subnet" {
  name       = "sub_subnet"
  network_id = "${openstack_networking_network_v2.sub_network.id}"
  cidr       = "192.168.90.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}
#Creating Port parent and sub port
resource "openstack_networking_port_v2" "parent_port" {
  depends_on = [
    "openstack_networking_subnet_v2.parent_subnet",
  ]

  name           = "parent_port"
  network_id     = "${openstack_networking_network_v2.parent_network.id}"
  admin_state_up = "true"

    fixed_ip {
    subnet_id  =  "${openstack_networking_subnet_v2.parent_subnet.id}"
    ip_address = "192.168.70.10"
  }
}

resource "openstack_networking_port_v2" "sub_port" {
  depends_on = [
    "openstack_networking_subnet_v2.sub_subnet",
  ]

  name           = "sub_port"
  network_id     = "${openstack_networking_network_v2.sub_network.id}"
  admin_state_up = "true"

    fixed_ip {
    subnet_id  =  "${openstack_networking_subnet_v2.sub_subnet.id}"
    ip_address = "192.168.90.10"
  }
}



#Adding subnets to router
resource "openstack_networking_router_interface_v2" "parent_router_interface" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.parent_subnet.id}"
}
resource "openstack_networking_router_interface_v2" "sub_router_interface" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.sub_subnet.id}"
}
resource "openstack_networking_trunk_v2" "trunk_1" {
  name           = "trunk_1"
  admin_state_up = "true"
  port_id        = "${openstack_networking_port_v2.parent_port.id}"

  sub_port {
    port_id           = "${openstack_networking_port_v2.sub_port.id}"
    segmentation_id   = 220
    segmentation_type = "vlan"
  }
}
#Creating floating ip
resource "openstack_networking_floatingip_v2" "vlan_floatip" {
  pool = "public"
}

# Creating Instance Resource
resource "openstack_compute_instance_v2" "vlanaware_instance_1" {
  name            = "vlanaware_instance_1"
  security_groups = ["default"]
  image_name	= "${var.IMAGE_NAME}"
  flavor_name	= "${var.FLAVOR_NAME}"
  key_pair	= "${var.SSH_KEY_NAME}"
  availability_zone = "${lookup(var.ZONE, var.AVAILABILITY_ZONES)}"
  network {
    port = "${openstack_networking_trunk_v2.trunk_1.port_id}"
  }
}
resource "openstack_compute_floatingip_associate_v2" "vlan_floatip" {
  floating_ip = "${openstack_networking_floatingip_v2.vlan_floatip.address}"
  instance_id = "${openstack_compute_instance_v2.vlanaware_instance_1.id}"
  wait_until_associated = "true"

//    provisioner "local-exec" {
//    command = "echo private_ip: ${openstack_compute_instance_v2.instance_2.access_ip_v4} \n public_ip:  ${openstack_networking_floatingip_v2.floatip_2.address}"
//  }
  connection {
      user     = "${var.SSH_USER_NAME}"
      host     = "${openstack_networking_floatingip_v2.vlan_floatip.address}"
      private_key = "${file(var.SSH_KEY_FILE)}"
    }

  provisioner "file"{
      source = "/home/osp_admin/OpenForm/ifcfg-eth0.220"
      destination = "/home/centos/ifcfg-eth.220"
  }
  provisioner "file"{
      source = "/home/osp_admin/OpenForm/router-eth0.220"
      destination = "/home/centos/router-eth.220"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/centos/ifcfg-eth.220 /etc/sysconfig/network-scripts/ifcfg-eth0.220",
      "sudo cp /home/centos/router-eth.220 /etc/sysconfig/network-scripts/router-eth0.220",
      "sudo ls -l /etc/sysconfig/network-scripts/",
      "sudo ifconfig",
      "sudo ls -l /etc/sysconfig/network-scripts/",
      "sudo cat /etc/sysconfig/network-scripts/ifcfg-eth0",
      "sudo ifup /etc/sysconfig/network-scripts/ifcfg-eth0.220",
      "sudo ifconfig",
      "ping -c 10 8.8.8.8",
      "ping -c 10 -I eth0.220 8.8.8.8"
    ]
}
}

#================================================================================================
#================================================================================================
#================================================================================================
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

resource "openstack_networking_port_v2" "port_2" {
  name               = "port_2"
  network_id         = "${openstack_networking_network_v2.network_1.id}"
  admin_state_up     = "true"
  #security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_1.id}"]

  fixed_ip {
    subnet_id  =  "${openstack_networking_subnet_v2.subnet_1.id}"
    ip_address = "192.168.199.11"
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
resource "openstack_networking_floatingip_v2" "floatip_2" {
  pool = "public"
}

# Creating Instance Resource
resource "openstack_compute_instance_v2" "instance_1" {
  name            = "instance_1"
  security_groups = ["default"]
  image_name	= "${var.IMAGE_NAME}"
  flavor_name	= "${var.FLAVOR_NAME}"
  key_pair	= "${var.SSH_KEY_NAME}"
  availability_zone = "${lookup(var.ZONE, var.AVAILABILITY_ZONES)}"
  network {
    port = "${openstack_networking_port_v2.port_1.id}"
  }
}

resource "openstack_compute_instance_v2" "instance_2" {
  name            = "instance_2"
  security_groups = ["default"]
  image_name	= "${var.IMAGE_NAME}"
  flavor_name	= "${var.FLAVOR_NAME}"
  key_pair	= "${var.SSH_KEY_NAME}"
  availability_zone = "${lookup(var.ZONE, var.AVAILABILITY_ZONES)}"
  network {
    port = "${openstack_networking_port_v2.port_2.id}"
  }
}

#Creating Resource for floating ip
resource "openstack_compute_floatingip_associate_v2" "floatip_2" {
  floating_ip = "${openstack_networking_floatingip_v2.floatip_2.address}"
  instance_id = "${openstack_compute_instance_v2.instance_2.id}"
  wait_until_associated = "true"

//    provisioner "local-exec" {
//    command = "echo private_ip: ${openstack_compute_instance_v2.instance_2.access_ip_v4} \n public_ip:  ${openstack_networking_floatingip_v2.floatip_2.address}"
//  }

}

resource "openstack_compute_floatingip_associate_v2" "floatip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.floatip_1.address}"
  instance_id = "${openstack_compute_instance_v2.instance_1.id}"
  wait_until_associated = "true"

//      provisioner "local-exec" {
//    command = "echo private_ip: ${openstack_compute_instance_v2.instance_1.access_ip_v4} \n public_ip:  ${openstack_networking_floatingip_v2.floatip_1.address}"
//  }

  #Creation a SSH Connection to Access VM and Perform a test in Created VM
    connection {
      user     = "${var.SSH_USER_NAME}"
      host     = "${openstack_networking_floatingip_v2.floatip_1.address}"
      private_key = "${file(var.SSH_KEY_FILE)}"
    }

  provisioner "file"{
      source = "/home/osp_admin/OpenForm/nginx.repo"
      destination = "/home/centos/nginx.repo"
  }

  provisioner "remote-exec" {
    inline = [
      "pwd",
      "ls",
      "sudo cat /etc/sysconfig/network-scripts/ifcfg-eth0",
      "sudo ls /etc/yum.repos.d/",
      "sudo cp nginx.repo /etc/yum.repos.d/",
      "sudo yum-config-manager --enable nginx",
      "sudo yum -y install nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl status nginx",
      "ping -c 10 ${openstack_compute_instance_v2.instance_2.access_ip_v4}",
    ]
}


}
output "instance_1_private_ip"{
  value = "${openstack_compute_instance_v2.instance_1.access_ip_v4}"
}
output "instance_2_private_ip"{
  value = "${openstack_compute_instance_v2.instance_2.access_ip_v4}"
}
output "vlanaware_instance_private_ip"{
  value = "${openstack_compute_instance_v2.vlanaware_instance_1.access_ip_v4}"
}
output "instance_1_public_ip"{
  value = "${openstack_networking_floatingip_v2.floatip_1.address}"
}
output "instance_2_public_ip"{
  value = "${openstack_networking_floatingip_v2.floatip_2.address}"
}
output "vlanaware_instance_public_ip"{
  value = "${openstack_networking_floatingip_v2.vlan_floatip.address}"
}