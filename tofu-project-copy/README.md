# Quick Project Copy

Blue and Red each have a **standalone OpenTofu root** (same layout as `tofu/`: `main.tf`, `workstations*.tf`, `variables.tf`, local `terraform.tfstate`). The shared stack is **symlinked** from `../tofu` so you do not fork `.tf` files.

- `blue/` — Blue workstations only (via `-target` in `deploy.sh`)
- `red/` — Red workstations only (via `-target` in `deploy.sh`)

## First-time setup (per folder)

```bash
cd tofu-project-copy/red   # or blue
./deploy.sh init
```

## Deploy (script wraps team targets)

```bash
cd tofu-project-copy/red
source /path/to/red-app-credential-openrc.sh
./deploy.sh plan
./deploy.sh apply
```

```bash
cd tofu-project-copy/blue
source /path/to/blue-app-credential-openrc.sh
./deploy.sh plan
./deploy.sh apply
```

Edit `project_ids.auto.tfvars` in each folder (`main_project_id`, team project id).

## Same as main `tofu/` — run OpenTofu directly

From `red/` or `blue/` you can run plain OpenTofu (state is `./terraform.tfstate` in that folder):

```bash
cd tofu-project-copy/red
tofu init -input=false
tofu plan -refresh=false -var-file=project_ids.auto.tfvars -target='openstack_compute_instance_v2.red_kali["07"]'
```

`project_ids.auto.tfvars` sets `plan_outputs_scope` to `red` or `blue` so outputs do not pull in the other team’s instances. `./deploy.sh plan` uses `-refresh=false` so the plan does not refresh every object in state (which used to print Blue “Refreshing state…” lines on Red plans). For a plan with full refresh, run `tofu plan -var-file=project_ids.auto.tfvars` plus your `-target`s manually and omit `-refresh=false`.

## Destroy VMs but keep SSH security groups

```bash
./deploy.sh destroy
```

## Notes

- **`plan_outputs_scope` does not choose the OpenStack project.** It only limits which outputs OpenTofu evaluates. VMs go where your **Keystone token** is scoped (`openstack token issue -f value -c project_id`) and where each resource’s `provider` points (`openstack.red` → `red_project_id` in tfvars).
- Sourced openrc files often set **`OS_PROJECT_ID`** / **`OS_TENANT_*`**. That can pin all API calls to Main even when tfvars say Delta/Foxtrot. `./deploy.sh` now **unsets** those before `tofu` and **aborts** if the token’s project does not match `red_project_id` / `blue_project_id` in `project_ids.auto.tfvars`.
- Use an **application credential created inside** the bridge project you deploy (Delta for Red, Foxtrot for Blue), not only Main.
- `-target` warnings are expected for these partial applies.
- Symlinks: `main.tf`, `workstations*.tf`, `outputs.tf`, `variables.tf`, `kali_bootstrap.sh.tftpl`, `.terraform.lock.hcl` → `../../tofu/...`.
