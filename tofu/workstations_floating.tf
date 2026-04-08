# Same as Horizon: allocate a floating IP from MAIN-NAT, then associate it to the VM's
# existing SCPmainnet port (primary NIC). No second port on the external network — avoids
# "create port on provider network" permission errors.

data "openstack_networking_network_v2" "floating_pool" {
  network_id = var.floating_ip_network_id
}

locals {
  fip_on   = var.workstation_enabled && var.workstation_floating_ips_enabled
  fip_pool = data.openstack_networking_network_v2.floating_pool.name
}

resource "openstack_networking_floatingip_v2" "blue_windows" {
  for_each = local.fip_on ? local.blue_windows : {}
  provider = openstack.blue
  pool     = local.fip_pool
}

resource "openstack_networking_floatingip_associate_v2" "blue_windows" {
  for_each    = local.fip_on ? local.blue_windows : {}
  provider    = openstack.blue
  floating_ip = openstack_networking_floatingip_v2.blue_windows[each.key].address
  port_id     = openstack_compute_instance_v2.blue_windows[each.key].network[0].port
  depends_on  = [openstack_networking_floatingip_v2.blue_windows]
}

resource "openstack_networking_floatingip_v2" "blue_linux" {
  for_each = local.fip_on ? local.blue_linux : {}
  provider = openstack.blue
  pool     = local.fip_pool
}

resource "openstack_networking_floatingip_associate_v2" "blue_linux" {
  for_each    = local.fip_on ? local.blue_linux : {}
  provider    = openstack.blue
  floating_ip = openstack_networking_floatingip_v2.blue_linux[each.key].address
  port_id     = openstack_compute_instance_v2.blue_linux[each.key].network[0].port
  depends_on  = [openstack_networking_floatingip_v2.blue_linux]
}

resource "openstack_networking_floatingip_v2" "red_kali" {
  for_each = local.fip_on ? local.red_kali : {}
  provider = openstack.red
  pool     = local.fip_pool
}

resource "openstack_networking_floatingip_associate_v2" "red_kali" {
  for_each    = local.fip_on ? local.red_kali : {}
  provider    = openstack.red
  floating_ip = openstack_networking_floatingip_v2.red_kali[each.key].address
  port_id     = openstack_compute_instance_v2.red_kali[each.key].network[0].port
  depends_on  = [openstack_networking_floatingip_v2.red_kali]
}

resource "openstack_networking_floatingip_v2" "red_windows" {
  for_each = local.fip_on ? local.red_windows : {}
  provider = openstack.red
  pool     = local.fip_pool
}

resource "openstack_networking_floatingip_associate_v2" "red_windows" {
  for_each    = local.fip_on ? local.red_windows : {}
  provider    = openstack.red
  floating_ip = openstack_networking_floatingip_v2.red_windows[each.key].address
  port_id     = openstack_compute_instance_v2.red_windows[each.key].network[0].port
  depends_on  = [openstack_networking_floatingip_v2.red_windows]
}
