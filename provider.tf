provider "openstack"{   
  user_name                     = "admin"
  tenant_name                   = "admin"
  password                      = "${var.OPENSTACK_ADMIN_PASSWORD}"
  auth_url                      = "${var.HORIZON_ACCESS_URL}"
  user_domain_name              = "Default"
  project_domain_name           = "Default"
  disable_no_cache_header       = true
}
