# Configure the OpenStack Provider
# Authenticating the Openstack with Admin User Credentials
provider "openstack" {
  user_name                     = "admin"
  tenant_name                   = "admin"
  password                      = "w77JAyu7Aj4gFKhneu9y88sd9"
  auth_url                      = "http://100.67.60.61:5000//v3"
  user_domain_name              = "Default"
  project_domain_name           = "Default"
  disable_no_cache_header       = true
}

# This will Create a ROUTER NAMED terraform_router and the resource name will be router_terraform
# External network id is for PUBLIC NETWORK
resource "openstack_networking_router_v2" "router_terraform" {
  name                = "terraform_router"
  admin_state_up      = true
  external_network_id = "252e901e-cf07-4b47-b243-f6cd11d4df96"
}

