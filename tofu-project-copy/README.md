# Quick Project Copy

Use this folder to deploy the same OpenTofu stack to another project set with minimal edits.

## What you edit

Only this file:

- `project_ids.auto.tfvars`

Set:

- `main_project_id`
- `blue_project_id`
- `red_project_id`

## How it works

- Reuses OpenTofu code from `../tofu`
- Keeps separate local state in this folder (`terraform.tfstate`)
- Avoids touching your original `tofu/terraform.tfstate`

## Commands

```bash
cd tofu-project-copy
source /path/to/new-openrc.sh
./deploy.sh plan
./deploy.sh apply
```

## Notes

- If the new environment uses a different network UUID, also set `main_network_id` in `project_ids.auto.tfvars`.
- RBAC sharing is still done with your existing helper (`tofu/deploy-range-scp.sh rbac`) using MAIN-project owner credentials.
