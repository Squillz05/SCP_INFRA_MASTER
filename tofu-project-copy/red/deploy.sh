#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TFVARS_FILE="$ROOT/project_ids.auto.tfvars"

usage() {
  echo "Usage: $0 [plan|apply|destroy|init]" >&2
  exit 1
}

if [[ ! -f "$TFVARS_FILE" ]]; then
  echo "Missing $TFVARS_FILE" >&2
  exit 1
fi

if [[ -z "${OS_APPLICATION_CREDENTIAL_ID:-}" || -z "${OS_APPLICATION_CREDENTIAL_SECRET:-}" ]]; then
  echo "OpenStack credentials not loaded. Run: source /path/to/openrc.sh" >&2
  exit 1
fi

cmd="${1:-plan}"
RED_TARGETS=(
  -target=openstack_networking_secgroup_v2.red_workstations_ssh
  -target=openstack_networking_secgroup_rule_v2.red_workstations_ssh_ingress
  -target=openstack_compute_instance_v2.red_kali
  -target=openstack_compute_instance_v2.red_windows
  -target=openstack_compute_interface_attach_v2.red_kali_main_nat
  -target=openstack_compute_interface_attach_v2.red_windows_main_nat
  -target=openstack_networking_floatingip_v2.red_kali
  -target=openstack_networking_floatingip_associate_v2.red_kali
  -target=openstack_networking_floatingip_v2.red_windows
  -target=openstack_networking_floatingip_associate_v2.red_windows
)
RED_DESTROY_TARGETS=(
  -target=openstack_compute_instance_v2.red_kali
  -target=openstack_compute_instance_v2.red_windows
  -target=openstack_compute_interface_attach_v2.red_kali_main_nat
  -target=openstack_compute_interface_attach_v2.red_windows_main_nat
  -target=openstack_networking_floatingip_v2.red_kali
  -target=openstack_networking_floatingip_associate_v2.red_kali
  -target=openstack_networking_floatingip_v2.red_windows
  -target=openstack_networking_floatingip_associate_v2.red_windows
)

cd "$ROOT"

case "$cmd" in
  init)
    tofu init -input=false
    ;;
  plan)
    tofu init -input=false
    tofu plan -var-file="$TFVARS_FILE" "${RED_TARGETS[@]}"
    ;;
  apply)
    tofu init -input=false
    tofu apply -var-file="$TFVARS_FILE" "${RED_TARGETS[@]}"
    ;;
  destroy)
    tofu init -input=false
    tofu destroy -var-file="$TFVARS_FILE" "${RED_DESTROY_TARGETS[@]}"
    ;;
  *)
    usage
    ;;
esac
