output "red_kali" {
  description = "Red Kali instances (name, id, fixed IP on boot network)."
  value = {
    for k, v in openstack_compute_instance_v2.red_kali : v.name => {
      id       = v.id
      fixed_ip = v.network[0].fixed_ip_v4
    }
  }
}

output "red_ubuntu" {
  description = "Red Ubuntu instances (name, id, fixed IP on boot network)."
  value = {
    for k, v in openstack_compute_instance_v2.red_ubuntu : v.name => {
      id       = v.id
      fixed_ip = v.network[0].fixed_ip_v4
    }
  }
}
