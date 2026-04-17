#!/usr/bin/env bash
set -euo pipefail

# Minimal Red deploy: creates Kali + Ubuntu VMs (flavor + image + name only).
# Attach networks, security groups, and extra interfaces in Horizon or the CLI.
#
# If this directory still has an old terraform.tfstate from the symlinked stack,
# the first plan may destroy resources that are no longer in configuration (for
# example old Windows instances or security groups). Inspect the plan before apply.
# To stop managing a server without deleting it, remove it from state: tofu state rm '<address>'.

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

cd "$ROOT"
team_openstack_clear_project_env

case "$cmd" in
  init)
    tofu init -input=false
    ;;
  plan)
    tofu init -input=false
    team_openstack_assert_token_matches_tfvars red "$TFVARS_FILE" "$ROOT"
    tofu plan -var-file="$TFVARS_FILE"
    ;;
  apply)
    tofu init -input=false
    team_openstack_assert_token_matches_tfvars red "$TFVARS_FILE" "$ROOT"
    tofu apply -var-file="$TFVARS_FILE"
    ;;
  destroy)
    tofu init -input=false
    team_openstack_assert_token_matches_tfvars red "$TFVARS_FILE" "$ROOT"
    tofu destroy -var-file="$TFVARS_FILE"
    ;;
  *)
    usage
    ;;
esac
