variable "main_project_id" {
  type        = string
  description = "Keystone project ID for Grey / default OpenStack provider."
  default     = "e5c8122da40747928b67b707f5f00961"
}

variable "blue_project_id" {
  type        = string
  description = "Keystone project ID where Blue Team workstations are created."
  default     = "bf49348094ba4708b0ea9f913bb7e6f2"
}

variable "red_project_id" {
  type        = string
  description = "Keystone project ID where Red Team workstations are created."
  default     = "7564cb869e4347b49f3ff18cba582102"
}

# --- Network (SCPmainnet in main project; typically shared to Blue/Red via Neutron RBAC) ---
# Workstation fixed IPs are 10.10.10.x on SCPmainnet (Blue .41-.49, Red .61-.70; avoid colliding with services).

variable "main_network_id" {
  type        = string
  description = "Neutron UUID for SCPmainnet (owned in main project)."
  default     = "ec2ac4a5-e5af-464c-bb0c-f65bad9e2f43"
}

# --- Images & sizing ---

variable "windows_image_name" {
  type        = string
  description = "Glance image name for Windows 11 workstations (Blue/Red)."
  default     = "Windows11"
}

variable "ubuntu_image_name" {
  type        = string
  description = "Glance image name for Ubuntu 22.04 (e.g. jammy)."
  default     = "Ubuntu2204Desktop"
}

variable "kali_image_name" {
  type        = string
  description = "Glance image name for Kali 2025."
  default     = "Kali2025"
}

variable "flavor_name" {
  type        = string
  description = "Flavor for all workstations (Windows, Ubuntu, Kali)."
  default     = "large"
}

variable "linux_key_pair" {
  type        = string
  description = "Key pair name injected on Linux instances (optional)."
  default     = ""
}

variable "security_group_names" {
  type        = list(string)
  description = "Security group names attached to every workstation (e.g. [\"default\", \"ssh\"])."
  default     = ["default"]
}

variable "workstation_enabled" {
  type        = bool
  description = "Set false to skip creating all workstation instances (plan/validate only)."
  default     = true
}

variable "workstation_floating_ips_enabled" {
  type        = bool
  description = "Allocate a floating IP from MAIN-NAT per workstation and associate to its existing SCPmainnet NIC. Distinct from workstation_main_nat_interfaces_enabled (second vNIC)."
  default     = false
}

variable "floating_ip_network_id" {
  type        = string
  description = "MAIN-NAT Neutron UUID (2f96295c-…): external pool for floating IPs, or target network for second NIC when workstation_main_nat_interfaces_enabled."
  default     = "2f96295c-34f6-49a2-b5cf-7f5b407be0c8"
}

variable "workstation_main_nat_interfaces_enabled" {
  type        = bool
  description = "Second vNIC on MAIN-NAT via Nova attach (network_id only; avoids Terraform-managed Neutron port create)."
  default     = true
}

variable "kali_ssh_port_enabled" {
  type        = bool
  description = "Create and attach project-scoped workstation security groups that allow inbound SSH (TCP/22) for all Blue and Red workstations."
  default     = true
}

variable "kali_ssh_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to reach workstation SSH (TCP/22) when kali_ssh_port_enabled is true."
  default     = ["0.0.0.0/0"]
}

variable "kali_bootstrap_user_data_enabled" {
  type        = bool
  description = "Apply a bootstrap script at Kali instance creation time via OpenStack user_data."
  default     = true
}

variable "kali_ssh_username" {
  type        = string
  description = "Username on Kali image that should receive authorized_keys entries."
  default     = "cyberrange"
}

variable "kali_ssh_authorized_keys" {
  type        = list(string)
  description = "Extra SSH public keys written to the Kali user's authorized_keys by bootstrap."
  default     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/GxJPyL4suVp9qJifEMBlJBQlKEkzJ2A1yg2ADgs9Cd28K3mGFq8b6QIGuR+XVvTG/JpDNcdncml7UnmZnWZvkZ3P7w7Gf2sacA5ppYceLwLjPNVF7qydkplLbU0SFk8is9JORv0g/Uo4ZvequTc0Z34XusFkn79TwHxRzXQ3EGZTEhmAahAPVKq71ebQVBoOfmbMDHipOXrAHx0j+pkpZTrbUozUIv0VrAMX89AMn/5UUUf14rScGJeacJQAHT5DqJJozycgfXYJNS4EHm5Un+mnZHttk9Bg0n7mW0PDi7+83B6vBf/zR2D67EE5D3amYYrtxwhmjH1rL4lE33Od"]
}

variable "kali_password_auth_enabled" {
  type        = bool
  description = "Whether cloud-init bootstrap enables SSH password authentication on Kali."
  default     = true
}

variable "kali_login_password" {
  type        = string
  description = "Plaintext password for user cyberrange at first boot (set via chpasswd; encoded in user_data as base64). Leave empty to skip."
  default     = "Cyberrange123!"
  sensitive   = true
}

variable "plan_outputs_scope" {
  type        = string
  description = "Which workstation outputs to evaluate in plan/apply output (red/blue/all). Does NOT change OpenStack project; provider tenant_id and your credential scope do."
  default     = "all"

  validation {
    condition     = contains(["all", "red", "blue"], var.plan_outputs_scope)
    error_message = "plan_outputs_scope must be all, red, or blue."
  }
}
