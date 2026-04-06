# Second vNIC on MAIN-NAT: use Nova attach-by-network (Horizon “Attach Interface” path).
# Avoids Neutron POST /v2.ports from the operator token, which hit PolicyNotAuthorized on this cloud.

locals {
  main_nat_iface_on = var.workstation_enabled && var.workstation_main_nat_interfaces_enabled
}

resource "openstack_compute_interface_attach_v2" "blue_windows_main_nat" {
  for_each    = local.main_nat_iface_on ? local.blue_windows : {}
  provider    = openstack.blue
  instance_id = openstack_compute_instance_v2.blue_windows[each.key].id
  network_id  = var.floating_ip_network_id
}

resource "openstack_compute_interface_attach_v2" "blue_linux_main_nat" {
  for_each    = local.main_nat_iface_on ? local.blue_linux : {}
  provider    = openstack.blue
  instance_id = openstack_compute_instance_v2.blue_linux[each.key].id
  network_id  = var.floating_ip_network_id
}

resource "openstack_compute_interface_attach_v2" "red_kali_main_nat" {
  for_each    = local.main_nat_iface_on ? local.red_kali : {}
  provider    = openstack.red
  instance_id = openstack_compute_instance_v2.red_kali[each.key].id
  network_id  = var.floating_ip_network_id
}

resource "openstack_compute_interface_attach_v2" "red_windows_main_nat" {
  for_each    = local.main_nat_iface_on ? local.red_windows : {}
  provider    = openstack.red
  instance_id = openstack_compute_instance_v2.red_windows[each.key].id
  network_id  = var.floating_ip_network_id
}

# Resolve addresses after attach (port_id is computed on the attach resource).
data "openstack_networking_port_v2" "blue_windows_main_nat" {
  for_each   = local.main_nat_iface_on ? local.blue_windows : {}
  provider   = openstack.blue
  port_id    = openstack_compute_interface_attach_v2.blue_windows_main_nat[each.key].port_id
  depends_on = [openstack_compute_interface_attach_v2.blue_windows_main_nat]
}

data "openstack_networking_port_v2" "blue_linux_main_nat" {
  for_each   = local.main_nat_iface_on ? local.blue_linux : {}
  provider   = openstack.blue
  port_id    = openstack_compute_interface_attach_v2.blue_linux_main_nat[each.key].port_id
  depends_on = [openstack_compute_interface_attach_v2.blue_linux_main_nat]
}

data "openstack_networking_port_v2" "red_kali_main_nat" {
  for_each   = local.main_nat_iface_on ? local.red_kali : {}
  provider   = openstack.red
  port_id    = openstack_compute_interface_attach_v2.red_kali_main_nat[each.key].port_id
  depends_on = [openstack_compute_interface_attach_v2.red_kali_main_nat]
}

data "openstack_networking_port_v2" "red_windows_main_nat" {
  for_each   = local.main_nat_iface_on ? local.red_windows : {}
  provider   = openstack.red
  port_id    = openstack_compute_interface_attach_v2.red_windows_main_nat[each.key].port_id
  depends_on = [openstack_compute_interface_attach_v2.red_windows_main_nat]
}
