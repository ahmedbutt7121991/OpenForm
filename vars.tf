variable "OPENSTACK_ADMIN_PASSWORD" {}
variable "HORIZON_ACCESS_URL"	    {}
variable "SECURITY_GROUP_ID"	    {}
variable "IMAGE_NAME"		    {}
variable "FLAVOR_NAME"		    {}
variable "SSH_KEY_NAME"		    {}
variable "SSH_USER_NAME"	    {}
variable "SSH_KEY_FILE"		    {}
variable "AVAILABILITY_ZONES" {
  default = "compute"
}
variable "ZONE" {
  type = "map"
  default = {
    compute = "nova"
    compute0 = "nova0"
    compute1 = "nova1"
    compute2 = "nova2"
  }
}