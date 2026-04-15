#!/usr/bin/env bash
# Shared helpers for blue/ red deploy scripts.
# OpenStack provider blocks set tenant_id per alias; shell OS_PROJECT_ID/OS_TENANT_*
# from a sourced openrc can still pin auth to the wrong project — clear before tofu.

team_openstack_clear_project_env() {
  unset OS_PROJECT_ID OS_PROJECT_NAME OS_TENANT_ID OS_TENANT_NAME
}

# Args: team (red|blue), tfvars path, working dir (OpenTofu root with .tf files)
team_openstack_assert_token_matches_tfvars() {
  local team="$1"
  local tfvars="$2"
  local workdir="$3"
  local var_name="red_project_id"
  [[ "$team" == "blue" ]] && var_name="blue_project_id"

  if ! command -v openstack >/dev/null 2>&1; then
    echo "Note: openstack CLI not found; skipping token project check." >&2
    return 0
  fi

  local expected
  expected="$(cd "$workdir" && printf 'var.%s\n' "$var_name" | tofu console -var-file="$tfvars" -input=false 2>/dev/null | tr -d '\r\n\"[:space:]')"
  if [[ -z "$expected" || "$expected" == "null" ]]; then
    echo "Warning: could not read var.${var_name} from tfvars via tofu console." >&2
    return 0
  fi

  local token_project
  token_project="$(openstack token issue -f value -c project_id 2>/dev/null || true)"
  if [[ -z "$token_project" ]]; then
    echo "Warning: openstack token issue failed; skipping project check." >&2
    return 0
  fi

  if [[ "$token_project" != "$expected" ]]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "ERROR: Keystone token is scoped to the wrong project." >&2
    echo "  Token project_id: $token_project" >&2
    echo "  Expected (${var_name}): $expected" >&2
    echo "" >&2
    echo "plan_outputs_scope does NOT change the OpenStack project — it only filters outputs." >&2
    echo "Use an application credential created IN the ${team} bridge project (Delta/Foxtrot)," >&2
    echo "or a password openrc scoped to that project — not the Main (cdtecho) project." >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    return 1
  fi
}
