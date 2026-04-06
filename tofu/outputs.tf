output "blue_windows" {
  description = "Blue Team Windows 11 workstations."
  value = {
    for k, v in openstack_compute_instance_v2.blue_windows : v.name => {
      id        = v.id
      fixed_ip  = v.network[0].fixed_ip_v4
      addresses = v.access_ip_v4
    }
  }
}

output "blue_linux" {
  description = "Blue Team Ubuntu 22.04 workstations."
  value = {
    for k, v in openstack_compute_instance_v2.blue_linux : v.name => {
      id        = v.id
      fixed_ip  = v.network[0].fixed_ip_v4
      addresses = v.access_ip_v4
    }
  }
}

output "red_kali" {
  description = "Red Team Kali workstations."
  value = {
    for k, v in openstack_compute_instance_v2.red_kali : v.name => {
      id        = v.id
      fixed_ip  = v.network[0].fixed_ip_v4
      addresses = v.access_ip_v4
    }
  }
}

output "red_windows" {
  description = "Red Team Windows 11 workstations."
  value = {
    for k, v in openstack_compute_instance_v2.red_windows : v.name => {
      id        = v.id
      fixed_ip  = v.network[0].fixed_ip_v4
      addresses = v.access_ip_v4
    }
  }
}
