
terraform {
  required_version = ">= 1.0"
  # Minimum OpenTofu/Terraform version required
  # Prevents using old versions with missing features

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.52.1"
      # PROVIDER EXPLAINED:
      # A "provider" is a plugin that knows how to talk to a specific platform.
      # The OpenStack provider translates our .tf code into OpenStack API calls.
      #
      # "source" tells OpenTofu where to download the provider from.
      # "version" ensures compatibility and security updates.
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
      # External provider lets us run shell scripts and use their output.
      # Used here for credential validation.
    }
  }
}

provider "openstack" {
  auth_url  = "https://openstack.cyberrange.rit.edu:5000/v3"
  region    = "CyberRange"
  tenant_id = var.main_project_id
  # Unset OS_PROJECT_ID / OS_TENANT_* in the shell before tofu if provider aliases hit the wrong project.
}
provider "openstack" {
  alias     = "blue"
  auth_url  = "https://openstack.cyberrange.rit.edu:5000/v3"
  region    = "CyberRange"
  tenant_id = var.blue_project_id

  # BLUE TEAM:
  # Defenders who protect their infrastructure from Red Team attacks.
  # Their Windows and Linux VMs live in this project.
  # They can manage their VMs but can't see Red Team's Kali machines.
}

provider "openstack" {
  alias     = "red"
  auth_url  = "https://openstack.cyberrange.rit.edu:5000/v3"
  region    = "CyberRange"
  tenant_id = var.red_project_id

  # RED TEAM:
  # Attackers who try to compromise Blue Team infrastructure.
  # Their Kali Linux attack VMs live in this project.
  # They can manage their VMs but can't see Blue Team's servers.
}

data "external" "check_credentials" {
  program = ["bash", "-c", <<-EOT
    # Check if environment variables are set
    if [ -z "$OS_APPLICATION_CREDENTIAL_ID" ] || [ -z "$OS_APPLICATION_CREDENTIAL_SECRET" ]; then
      echo "" >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "❌ ERROR: OpenStack credentials not loaded!" >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "" >&2
      echo "You must source the credentials file before running tofu commands:" >&2
      echo "" >&2
      echo "    source ../app-cred-openrc.sh" >&2
      echo "" >&2
      echo "Then try running your tofu command again." >&2
      echo "" >&2
      echo "If you don't have the credentials file yet:" >&2
      echo "  1. Go to: https://openstack.cyberrange.rit.edu" >&2
      echo "  2. Navigate to: Identity → Application Credentials" >&2
      echo "  3. Create a new credential and download the openrc file" >&2
      echo "  4. Move it to the project root and run: ./quick-start.sh" >&2
      echo "" >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      exit 1
    fi

    # Return valid JSON if credentials are set
    echo '{"status":"ok"}'
  EOT
  ]
}