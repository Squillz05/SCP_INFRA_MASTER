data "openstack_networking_secgroup_v2" "redteam" {
  provider    = openstack.red
  secgroup_id = var.redteam_security_group_id
}
