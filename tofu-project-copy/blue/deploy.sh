#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TFVARS_FILE="$ROOT/project_ids.auto.tfvars"
# shellcheck source=../lib/team-openstack-env.sh
source "$ROOT/../lib/team-openstack-env.sh"

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
BLUE_TARGETS=(
  -target=openstack_networking_secgroup_v2.blue_workstations_ssh
  -target=openstack_networking_secgroup_rule_v2.blue_workstations_ssh_ingress
  -target=openstack_compute_instance_v2.blue_windows
  -target=openstack_compute_instance_v2.blue_linux
  -target=openstack_compute_interface_attach_v2.blue_windows_main_nat
  -target=openstack_compute_interface_attach_v2.blue_linux_main_nat
  -target=openstack_networking_floatingip_v2.blue_windows
  -target=openstack_networking_floatingip_associate_v2.blue_windows
  -target=openstack_networking_floatingip_v2.blue_linux
  -target=openstack_networking_floatingip_associate_v2.blue_linux
)
BLUE_DESTROY_TARGETS=(
  -target=openstack_compute_instance_v2.blue_windows
  -target=openstack_compute_instance_v2.blue_linux
  -target=openstack_compute_interface_attach_v2.blue_windows_main_nat
  -target=openstack_compute_interface_attach_v2.blue_linux_main_nat
  -target=openstack_networking_floatingip_v2.blue_windows
  -target=openstack_networking_floatingip_associate_v2.blue_windows
  -target=openstack_networking_floatingip_v2.blue_linux
  -target=openstack_networking_floatingip_associate_v2.blue_linux
)

cd "$ROOT"
team_openstack_clear_project_env

case "$cmd" in
  init)
    tofu init -input=false
    ;;
  plan)
    tofu init -input=false
    team_openstack_assert_token_matches_tfvars blue "$TFVARS_FILE" "$ROOT"
    tofu plan -refresh=false -var-file="$TFVARS_FILE" "${BLUE_TARGETS[@]}"
    ;;
  apply)
    tofu init -input=false
    team_openstack_assert_token_matches_tfvars blue "$TFVARS_FILE" "$ROOT"
    tofu apply -var-file="$TFVARS_FILE" "${BLUE_TARGETS[@]}"
    ;;
  destroy)
    tofu init -input=false
    team_openstack_assert_token_matches_tfvars blue "$TFVARS_FILE" "$ROOT"
    tofu destroy -var-file="$TFVARS_FILE" "${BLUE_DESTROY_TARGETS[@]}"
    ;;
  *)
    usage
    ;;
esac
