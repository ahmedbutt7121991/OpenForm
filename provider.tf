provider "openstack"{
  user_name                     = var.ADMIN_USERNAME
  tenant_name                   = var.ADMIN_TENANTNAME
  password                      = var.OPENSTACK_ADMIN_PASSWORD
  auth_url                      = var.HORIZON_ACCESS_URL
  user_domain_name              = "Default"
  project_domain_name           = "Default"
  disable_no_cache_header       = true
}
//provider "openstack"{
//  user_domain_name              = "Default"
//  project_domain_name           = "Default"
//  alias                         = "sanity"
//  user_name                     = "${var.SANITY_USERNAME}"
//  tenant_name                   = "${var.SANITY_TENANTNAME}"
//  password                      = "${var.OPENSTACK_SANITY_PASSWORD}"
//  auth_url                      = "${var.HORIZON_ACCESS_URL}"
//}
