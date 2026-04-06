locals {
  # Blue: Windows 11 BLUE-WIN-01..04 @ 10.10.10.41-44
  blue_windows = {
    "01" = "10.10.10.41"
    "02" = "10.10.10.42"
    "03" = "10.10.10.43"
    "04" = "10.10.10.44"
  }

  # Blue: Ubuntu 22.04 BLUE-LIN-01..05 @ 10.10.10.45-49
  blue_linux = {
    "01" = "10.10.10.45"
    "02" = "10.10.10.46"
    "03" = "10.10.10.47"
    "04" = "10.10.10.48"
    "05" = "10.10.10.49"
  }

  # Red: Kali RED-KALI-01..06 @ 10.10.10.61-66 (same /24 as Blue; clear of .41-.49 and .101-.104 services)
  red_kali = {
    "01" = "10.10.10.61"
    "02" = "10.10.10.62"
    "03" = "10.10.10.63"
    "04" = "10.10.10.64"
    "05" = "10.10.10.65"
    "06" = "10.10.10.66"
  }

  # Red: Windows 11 RED-WIN-01..04 @ 10.10.10.67-70
  red_windows = {
    "01" = "10.10.10.67"
    "02" = "10.10.10.68"
    "03" = "10.10.10.69"
    "04" = "10.10.10.70"
  }
}

resource "openstack_compute_instance_v2" "blue_windows" {
  for_each = var.workstation_enabled ? local.blue_windows : {}

  provider    = openstack.blue
  name        = "BLUE-WIN-${each.key}"
  flavor_name = var.flavor_name
  image_name  = var.windows_image_name

  security_groups = var.security_group_names

  network {
    uuid        = var.main_network_id
    fixed_ip_v4 = each.value
  }

  metadata = {
    team = "blue"
    role = "workstation"
    os   = "windows11"
  }

  depends_on = [data.external.check_credentials]
}

resource "openstack_compute_instance_v2" "blue_linux" {
  for_each = var.workstation_enabled ? local.blue_linux : {}

  provider    = openstack.blue
  name        = "BLUE-LIN-${each.key}"
  flavor_name = var.flavor_name
  image_name  = var.ubuntu_image_name

  security_groups = var.security_group_names
  key_pair        = var.linux_key_pair != "" ? var.linux_key_pair : null

  network {
    uuid        = var.main_network_id
    fixed_ip_v4 = each.value
  }

  metadata = {
    team = "blue"
    role = "workstation"
    os   = "ubuntu22"
  }

  depends_on = [data.external.check_credentials]
}

resource "openstack_compute_instance_v2" "red_kali" {
  for_each = var.workstation_enabled ? local.red_kali : {}

  provider    = openstack.red
  name        = "RED-KALI-${each.key}"
  flavor_name = var.flavor_name
  image_name  = var.kali_image_name

  security_groups = var.security_group_names
  key_pair        = var.linux_key_pair != "" ? var.linux_key_pair : null

  network {
    uuid        = var.main_network_id
    fixed_ip_v4 = each.value
  }

  metadata = {
    team = "red"
    role = "workstation"
    os   = "kali"
  }

  depends_on = [data.external.check_credentials]
}

resource "openstack_compute_instance_v2" "red_windows" {
  for_each = var.workstation_enabled ? local.red_windows : {}

  provider    = openstack.red
  name        = "RED-WIN-${each.key}"
  flavor_name = var.flavor_name
  image_name  = var.windows_image_name

  security_groups = var.security_group_names

  network {
    uuid        = var.main_network_id
    fixed_ip_v4 = each.value
  }

  metadata = {
    team = "red"
    role = "workstation"
    os   = "windows11"
  }

  depends_on = [data.external.check_credentials]
}
