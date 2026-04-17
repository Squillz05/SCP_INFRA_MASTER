variable "red_project_id" {
  type        = string
  description = "Keystone project ID for the Red team (where instances are created)."
}

variable "flavor_name" {
  type        = string
  description = "Nova flavor for all Red workstations."
  default     = "large"
}

variable "kali_image_name" {
  type        = string
  description = "Glance image name for Kali instances."
  default     = "Kali2025"
}

variable "ubuntu_image_name" {
  type        = string
  description = "Glance image name for Ubuntu instances."
  default     = "Ubuntu2204Desktop"
}

variable "linux_key_pair" {
  type        = string
  description = "Optional Nova key pair name. Leave empty to skip (attach access manually if needed)."
  default     = ""
}

variable "boot_network_id" {
  type        = string
  description = "Neutron network UUID for the boot NIC (required here: Nova does not pick a network automatically). Use your shared SCPmainnet UUID unless an admin gave you a different one. You can still change or add interfaces in Horizon; Terraform ignores drift on network."
  default     = "ec2ac4a5-e5af-464c-bb0c-f65bad9e2f43"

  validation {
    condition     = length(trimspace(var.boot_network_id)) > 0
    error_message = "boot_network_id must be a non-empty Neutron network UUID."
  }
}

variable "redteam_security_group_id" {
  type        = string
  description = "Neutron security group UUID for the Red team group attached to every workstation."
  default     = "e36b5afe-cab5-476a-adf9-7a3406c662cc"
}

variable "base_security_group_names" {
  type        = list(string)
  description = "Extra security group names always attached with the Redteam group (Nova replaces the whole list). Default includes project default."
  default     = ["default"]
}

variable "kali_bootstrap_user_data_enabled" {
  type        = bool
  description = "If true, pass kali_bootstrap.sh.tftpl as user_data and use config_drive on Red Kali instances only."
  default     = true
}

variable "kali_ssh_username" {
  type        = string
  description = "Kali user that receives authorized_keys from bootstrap."
  default     = "cyberrange"
}

variable "kali_ssh_authorized_keys" {
  type        = list(string)
  description = "SSH public keys appended on first boot (Kali only)."
  default     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/GxJPyL4suVp9qJifEMBlJBQlKEkzJ2A1yg2ADgs9Cd28K3mGFq8b6QIGuR+XVvTG/JpDNcdncml7UnmZnWZvkZ3P7w7Gf2sacA5ppYceLwLjPNVF7qydkplLbU0SFk8is9JORv0g/Uo4ZvequTc0Z34XusFkn79TwHxRzXQ3EGZTEhmAahAPVKq71ebQVBoOfmbMDHipOXrAHx0j+pkpZTrbUozUIv0VrAMX89AMn/5UUUf14rScGJeacJQAHT5DqJJozycgfXYJNS4EHm5Un+mnZHttk9Bg0n7mW0PDi7+83B6vBf/zR2D67EE5D3amYYrtxwhmjH1rL4lE33Od"]
}

variable "kali_password_auth_enabled" {
  type        = bool
  description = "Whether bootstrap enables SSH password authentication on Kali."
  default     = true
}

variable "kali_login_password" {
  type        = string
  description = "Plaintext password for user cyberrange at first boot (chpasswd via bootstrap). Empty skips."
  default     = "Cyberrange123!"
  sensitive   = true
}
