#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOFU_DIR="$ROOT/../tofu"
TFVARS_FILE="$ROOT/project_ids.auto.tfvars"
STATE_FILE="$ROOT/terraform.tfstate"

usage() {
  echo "Usage: $0 [plan|apply]" >&2
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
case "$cmd" in
  plan)
    (cd "$TOFU_DIR" && tofu init -input=false && tofu plan -var-file="$TFVARS_FILE" -state="$STATE_FILE")
    ;;
  apply)
    (cd "$TOFU_DIR" && tofu init -input=false && tofu apply -var-file="$TFVARS_FILE" -state="$STATE_FILE")
    ;;
  *)
    usage
    ;;
esac
