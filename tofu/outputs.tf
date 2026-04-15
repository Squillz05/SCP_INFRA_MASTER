locals {
  output_include_blue = var.plan_outputs_scope == "all" || var.plan_outputs_scope == "blue"
  output_include_red  = var.plan_outputs_scope == "all" || var.plan_outputs_scope == "red"
}

output "blue_windows" {
  description = "Blue Team Windows 11 workstations."
  value = local.output_include_blue ? {
    for k, v in openstack_compute_instance_v2.blue_windows : v.name => {
      id        = v.id
      fixed_ip  = v.network[0].fixed_ip_v4
      addresses = v.access_ip_v4
    }
  } : {}
}

output "blue_linux" {
  description = "Blue Team Ubuntu 22.04 workstations."
  value = local.output_include_blue ? {
    for k, v in openstack_compute_instance_v2.blue_linux : v.name => {
      id        = v.id
      fixed_ip  = v.network[0].fixed_ip_v4
      addresses = v.access_ip_v4
    }
  } : {}
}

output "red_kali" {
  description = "Red Team Kali workstations."
  value = local.output_include_red ? {
    for k, v in openstack_compute_instance_v2.red_kali : v.name => {
      id        = v.id
      fixed_ip  = v.network[0].fixed_ip_v4
      addresses = v.access_ip_v4
    }
  } : {}
}

output "red_windows" {
  description = "Red Team Windows 11 workstations."
  value = local.output_include_red ? {
    for k, v in openstack_compute_instance_v2.red_windows : v.name => {
      id        = v.id
      fixed_ip  = v.network[0].fixed_ip_v4
      addresses = v.access_ip_v4
    }
  } : {}
}

output "workstation_floating_ip_settings" {
  description = "Floating IP from MAIN-NAT pool attached to primary interfaces."
  value = {
    floating_ips_enabled = var.workstation_floating_ips_enabled && var.workstation_enabled
    pool_network_id      = var.floating_ip_network_id
  }
}

output "workstation_floating_ips" {
  description = "Public floating IP per VM (empty when workstation_floating_ips_enabled is false)."
  value = merge(
    local.output_include_blue ? { for k, v in openstack_networking_floatingip_v2.blue_windows : openstack_compute_instance_v2.blue_windows[k].name => v.address } : {},
    local.output_include_blue ? { for k, v in openstack_networking_floatingip_v2.blue_linux : openstack_compute_instance_v2.blue_linux[k].name => v.address } : {},
    local.output_include_red ? { for k, v in openstack_networking_floatingip_v2.red_kali : openstack_compute_instance_v2.red_kali[k].name => v.address } : {},
    local.output_include_red ? { for k, v in openstack_networking_floatingip_v2.red_windows : openstack_compute_instance_v2.red_windows[k].name => v.address } : {},
  )
}

output "workstation_main_nat_interface_settings" {
  description = "Second NIC on MAIN-NAT toggle."
  value = {
    main_nat_interfaces_enabled = var.workstation_main_nat_interfaces_enabled && var.workstation_enabled
    network_id                  = var.floating_ip_network_id
  }
}

output "workstation_main_nat_interface_ips" {
  description = "Address on the MAIN-NAT-attached port per VM (empty when workstation_main_nat_interfaces_enabled is false)."
  value = merge(
    local.output_include_blue ? { for k, v in data.openstack_networking_port_v2.blue_windows_main_nat : openstack_compute_instance_v2.blue_windows[k].name => one(v.all_fixed_ips) } : {},
    local.output_include_blue ? { for k, v in data.openstack_networking_port_v2.blue_linux_main_nat : openstack_compute_instance_v2.blue_linux[k].name => one(v.all_fixed_ips) } : {},
    local.output_include_red ? { for k, v in data.openstack_networking_port_v2.red_kali_main_nat : openstack_compute_instance_v2.red_kali[k].name => one(v.all_fixed_ips) } : {},
    local.output_include_red ? { for k, v in data.openstack_networking_port_v2.red_windows_main_nat : openstack_compute_instance_v2.red_windows[k].name => one(v.all_fixed_ips) } : {},
  )
}
