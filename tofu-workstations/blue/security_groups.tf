data "openstack_networking_secgroup_v2" "blueteam" {
  provider    = openstack.main
  secgroup_id = var.blueteam_security_group_id
}
