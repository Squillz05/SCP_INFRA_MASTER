locals {
  red_kali_keys   = toset(["01", "02", "03", "04", "05", "06"])
  red_ubuntu_keys = toset(["01", "02", "03"])

  workstation_security_groups = distinct(concat(
    var.base_security_group_names,
    [data.openstack_networking_secgroup_v2.redteam.name],
  ))

  # RED-KALI-01..06 @ 10.10.10.80-85; RED-UBUNTU-01..03 @ 10.10.10.86-88
  red_kali_fixed_ips = {
    "01" = "10.10.10.80"
    "02" = "10.10.10.81"
    "03" = "10.10.10.82"
    "04" = "10.10.10.83"
    "05" = "10.10.10.84"
    "06" = "10.10.10.85"
  }
  red_ubuntu_fixed_ips = {
    "01" = "10.10.10.86"
    "02" = "10.10.10.87"
    "03" = "10.10.10.88"
  }
}

resource "openstack_compute_instance_v2" "red_kali" {
  for_each = local.red_kali_keys

  provider = openstack.red

  name        = "RED-KALI-${each.key}"
  flavor_name = var.flavor_name
  image_name  = var.kali_image_name
  key_pair    = var.linux_key_pair != "" ? var.linux_key_pair : null

  user_data = var.kali_bootstrap_user_data_enabled ? templatefile("${path.module}/kali_bootstrap.sh.tftpl", {
    kali_ssh_username            = var.kali_ssh_username
    kali_ssh_authorized_keys     = var.kali_ssh_authorized_keys
    kali_password_auth_enabled   = var.kali_password_auth_enabled
    kali_login_chpasswd_line_b64 = var.kali_login_password == "" ? "" : base64encode("cyberrange:${var.kali_login_password}")
  }) : null
  config_drive = var.kali_bootstrap_user_data_enabled

  security_groups = local.workstation_security_groups

  network {
    uuid        = var.boot_network_id
    fixed_ip_v4 = local.red_kali_fixed_ips[each.key]
  }

  lifecycle {
    ignore_changes = [
      user_data,
      config_drive,
      metadata,
    ]
  }
}

resource "openstack_compute_instance_v2" "red_ubuntu" {
  for_each = local.red_ubuntu_keys

  provider = openstack.red

  name        = "RED-UBUNTU-${each.key}"
  flavor_name = var.flavor_name
  image_name  = var.ubuntu_image_name
  key_pair    = var.linux_key_pair != "" ? var.linux_key_pair : null

  security_groups = local.workstation_security_groups

  network {
    uuid        = var.boot_network_id
    fixed_ip_v4 = local.red_ubuntu_fixed_ips[each.key]
  }

  lifecycle {
    ignore_changes = [
      user_data,
      config_drive,
      metadata,
    ]
  }
}
