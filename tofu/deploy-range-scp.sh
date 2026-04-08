#!/usr/bin/env bash
# SCP Echo / Grey Team — deployment helper (parallel to deploy-range.sh).
#
# Unlike deploy-range.sh, this does NOT create Arasaka-style networks or grey scoring VMs.
# SCP services (DC, Linux, etc.) are assumed already live on 10.10.10.x via Ansible/other.
#
# This script:
#   rbac  — share SCPmainnet from the main project to Blue/Red (Neutron RBAC); run once or when projects change.
#   plan  — OpenTofu plan for workstations (workstations.tf).
#   apply — OpenTofu apply for Blue/Red workstations (same IPs/names as workstations.tf).
#
# Workloads deployed by OpenTofu:
#   Blue: BLUE-WIN-01..04 (10.10.10.41-44), BLUE-LIN-01..05 (10.10.10.45-49)
#   Red:  RED-KALI-01..06 (10.10.10.61-66), RED-WIN-01..04 (10.10.10.67-70)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOFU_DIR="$ROOT/tofu"
OPENRC_FILE="${OPENRC_FILE:-$ROOT/app-cred-openrc.sh}"

# --- Match tofu/variables.tf (main project owns SCPmainnet) ---
MAIN_PROJECT_ID="e5c8122da40747928b67b707f5f00961"
BLUE_PROJECT_ID="bf49348094ba4708b0ea9f913bb7e6f2"
RED_PROJECT_ID="7564cb869e4347b49f3ff18cba582102"

MAIN_NETWORK_NAME="SCPmainnet"
MAIN_NETWORK_ID="ec2ac4a5-e5af-464c-bb0c-f65bad9e2f43"

# OpenTofu defaults (override via tofu/terraform.tfvars)
# flavor_name: m1.large | windows: "Windows 11" | ubuntu / kali: variables in tf

usage() {
  echo "Usage: $0 [rbac|plan|apply]" >&2
  echo "  (default) apply — OpenTofu apply for workstations" >&2
  echo "  rbac  — share SCPmainnet to Blue & Red (main-project OpenStack CLI; run once)" >&2
  echo "  plan  — OpenTofu plan" >&2
  echo "Env: OPENRC_FILE (default: repo root app-cred-openrc.sh)" >&2
  exit 1
}

source_openrc() {
  if [[ ! -f "$OPENRC_FILE" ]]; then
    echo "ERROR: OpenStack credentials not found: $OPENRC_FILE" >&2
    echo "Set OPENRC_FILE or place app-cred-openrc.sh at the repo root." >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$OPENRC_FILE"
}

cmd_rbac() {
  source_openrc
  echo "Sharing network $MAIN_NETWORK_NAME ($MAIN_NETWORK_ID) with Blue ($BLUE_PROJECT_ID) and Red ($RED_PROJECT_ID)..."
  echo "Run this with credentials scoped to the MAIN project that owns the network."
  openstack network rbac create \
    --target-project "$BLUE_PROJECT_ID" --action access_as_shared --type network "$MAIN_NETWORK_ID"
  openstack network rbac create \
    --target-project "$RED_PROJECT_ID" --action access_as_shared --type network "$MAIN_NETWORK_ID"
  echo "RBAC rules created. If OpenStack says they already exist, sharing is already in place."
}

cmd_plan() {
  source_openrc
  (cd "$TOFU_DIR" && tofu init -input=false && tofu plan)
}

cmd_apply() {
  source_openrc
  (cd "$TOFU_DIR" && tofu init -input=false && tofu apply)
}

cmd="${1:-apply}"
case "$cmd" in
  -h|--help|help) usage ;;
  rbac)  cmd_rbac ;;
  plan)  cmd_plan ;;
  apply) cmd_apply ;;
  *)     echo "Unknown command: $cmd" >&2; usage ;;
esac

echo "Done."
