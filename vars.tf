variable "ADMIN_USERNAME" {
  default = "admin"
}
variable "ADMIN_TENANTNAME" {
  default = "admin"
}
variable "OPENSTACK_ADMIN_PASSWORD" {
  default = "wnny7DPCPEYTGsnPQQTCBPkuN"
}
variable "SANITY_USERNAME" {
  default = "sanity_user_1"
}
variable "SANITY_TENANTNAME" {
  default = "sanity_project_1"
}
variable "OPENSTACK_SANITY_PASSWORD" {
  default = "s@n!ty"
}
variable "HORIZON_ACCESS_URL"	    {}
variable "SECURITY_GROUP_ID"	    {}
variable "IMAGE_NAME"		    {}
variable "FLAVOR_NAME"		    {}
variable "SSH_KEY_NAME"		    {}
variable "SSH_USER_NAME"	    {}
variable "SSH_KEY_FILE"		    {}
//variable "AVAILABILITY_ZONES" {
//  default = "compute"
//}
//variable "ZONE" {
//  type = "map"
//  default = {
//    compute = "nova"
//    compute0 = "nova0"
//    compute1 = "nova1"
//    compute2 = "nova2"
//  }
//}
variable "network" {
  default = "public"
}
variable "public_network" {
  default = "public"
}
data "openstack_compute_availability_zones_v2" "zones" {}
