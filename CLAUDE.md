# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

GitHub Actions workflows + Terraform templates for deploying Azure infrastructure (chiefly Azure Databricks workspaces) across multiple teams and environments, authenticated via Azure OIDC. State lives in Azure Blob Storage.

## Deployment surface

There is now a single deployment flow — the multi-team Databricks workspace pipeline. The previous single-environment example flow (`terraform/environments/{staging,production}`, `terraform/modules/example`, `config/envs/*.json`, `terraform-main.yml`, and the Terratest harness) has been removed.

### Multi-team Databricks flow

Driven by `.github/workflows/terraform-databricks.yml`. The root Terraform module is `terraform/databricks/` and the reusable module is `terraform/modules/databricks-workspace/`. Per-team configuration lives in `config/teams/<team>/`:

```
config/teams/<team>/
  common.tfvars        # team-wide vars (team_name, sku, tags)
  envs/<env>.tfvars    # per-env vars (environment, resource_group_name, subnet IDs, compliance_profile)
```

The set of environments for a team is **inferred from the filenames in `envs/`** — add or remove a `<env>.tfvars` file to add or remove an env. The `_template/` folder and `example-team-{2,4}env/` folders (all under `config/teams/`) illustrate the 2-env (staging+prod) and 4-env (dev+qa+staging+prod) layouts. The per-env tfvars are intended to grow over time — additional resource types (e.g. key vault) will share the same file rather than living in a parallel folder tree.

**Pipeline shape** (jobs in order):
1. `_config` — reads `config/global/base.json` for runner labels and Teams webhook.
2. `detect-changes` — on PR, diffs against the base to find changed teams; on manual dispatch, honours `team`/`environment` inputs (`all` expands). Module-file changes queue **all** teams. Builds a matrix of `{team, environment, subscription_alias}` tuples.
3. `plan` — runs per matrix entry. Calls `terraform plan` with `-var-file=../../config/teams/<team>/common.tfvars -var-file=../../config/teams/<team>/envs/<env>.tfvars`. Uploads the plan as an artifact `tfplan-<team>-<env>`.
4. `apply-lower` — applies dev/qa. Only fires on `workflow_dispatch` from `develop` or `main` (PR triggers are excluded via `github.event_name != 'pull_request'`).
5. `apply-upper` — applies staging/prod. Only fires on `workflow_dispatch` from `main`, gated by the `databricks-<env>` GitHub Environment (manual approval).

**Triggers:** PRs run plan only. Apply is manual via `workflow_dispatch` — there is no push trigger.

**Subscription routing & tier metadata.** `config/global/subscriptions.json` is the source of truth for per-env metadata. Each env under `.environments` carries a `subscription` alias and a `requires_approval` flag (currently `dev`/`qa` → `dev-qa` + `requires_approval: false`, `staging`/`prod` → `staging-prod` + `requires_approval: true`). The `apply-lower` vs `apply-upper` split, and the `environment: databricks-<env>` job-level gating in the ops workflows, are both driven by `requires_approval` — no env names are hardcoded in shell or in `if` expressions. Adding a new tier (e.g. `uat`) means: add the entry to `subscriptions.json`, add the matching `databricks-uat` GitHub Environment if `requires_approval: true`, and update the `environment` validation list in [terraform/databricks/variables.tf](terraform/databricks/variables.tf). Each subscription alias has its own GitHub secrets exposed as env vars; a shell `case "$ALIAS"` block in the composite `resolve-subscription` action picks the right `AZURE_*` and `TF_*` values. GitHub Actions doesn't support `secrets[variable]` dynamic indexing — that's why the indirection exists.

**State key convention:** `workspace/<team>/<env>.tfstate` in the container named by `subscriptions.<alias>.state_container`.

**Required secrets** for this flow: `AZURE_TENANT_ID`, plus the four `AZURE_{CLIENT_ID,SUBSCRIPTION}_{DEV_QA,STAGING_PROD}` and `TF_STATE_{STORAGE_ACCOUNT,RESOURCE_GROUP}_{DEV_QA,STAGING_PROD}`. Optional: `TEAMS_WEBHOOK_URL`.

### Ops workflows (same team × env model)

The following workflows all share the same `team` + `environment` model and the same `Resolve subscription credentials` shell pattern as `terraform-databricks.yml`. They target the same `terraform/databricks/` root and the same `workspace/<team>/<env>.tfstate` state keys:

- `terraform-drift-detection.yml` — weekly + manual. Fans out across every `{team, env}` under `config/teams/`, runs `terraform plan -detailed-exitcode`, uploads drift artifacts, notifies Teams.
- `terraform-state-management.yml` — `unlock | list | show | remove | backup | restore` on a single `{team, env}`. Scheduled cron does a backup over every `{team, env}`.
- `terraform-compliance.yml` — `tflint` + `checkov` + `az policy state list` (RG resolved from the env tfvars). PR trigger derives slices from changed files; manual takes `team`/`environment` inputs (each accepts `all`).
- `terraform-utilities.yml` — `tfupdate` (single root, no per-env duplication), `dependency-graph`, `target-apply`/`target-destroy`, and **config-driven import** via `import-plan` / `import-apply`. Both render Terraform `import {}` blocks (>= 1.5) into an ephemeral `generated_imports.tf` from **either** a bulk `import_config_file` **or** the single `import_resource_address` + `import_resource_id` pair. `import-plan` runs `terraform plan -generate-config-out=workspace.generated.tf` (preview only — uploads the generated HCL + plan text as artifacts, changes no state); for resources already coded in the module the generated file is empty by design (`-generate-config-out` only emits HCL for not-yet-coded targets, and it cannot be combined with `-out`). `import-apply` does a state backup → `plan -out=import.tfplan` → `apply` → `-detailed-exitcode` post-import verify. Bulk-import files live under `config/imports/<team>/<env>-imports.json` (templates in `config/imports/_template/`).
- `terraform-testing.yml` — static checks only: `terraform fmt -check`, `terraform validate` against the root and the module (with `-backend=false`), and `tflint`. No Azure resources created.

The state-management, utilities, and compliance workflows gate `staging`/`prod` slices on the `databricks-<env>` GitHub Environment, matching `terraform-databricks.yml`.

## Key invariants and gotchas

- **`compliance_profile = "enhanced"` requires `sku = "premium"`.** Enforced as a `check` block in [terraform/databricks/variables.tf](terraform/databricks/variables.tf) (warning only — Terraform `check` cannot fail a plan) **and** as a `precondition` on a `terraform_data` resource in [terraform/modules/databricks-workspace/main.tf](terraform/modules/databricks-workspace/main.tf) (this one *does* fail the plan). The provider also rejects the combination at apply. Enhanced compliance is a **one-way** change — downgrading requires recreating the workspace.
- **`prevent_destroy = true`** on `azurerm_databricks_workspace.this`. Removing a team or env from `config/teams/` will not delete the workspace; the resource has to be removed from state (or the lifecycle rule flipped) explicitly.
- **Subnets are pre-existing.** `public_subnet_id`/`private_subnet_id` are passed in as full Azure resource IDs and must be provisioned out-of-band before applying. The module parses VNet ID + subnet names out of these via `regex(...)`.
- **Location is hardcoded** to `australiaeast` in `terraform/modules/databricks-workspace/main.tf` — change that one local if you need a different region.
- **`config/teams/_template/` is the scaffolding source**; the workflow skips it via `grep -v '^_'`. Don't rename it.
- **Workflow variable file paths** are relative to `terraform/databricks/`, so they look like `../../config/teams/<team>/common.tfvars` — keep this in mind when adding new `-var-file` arguments.

## Common commands

```bash
# Scaffold a new team (4-env: dev/qa/staging/prod is the default; pass 2 for staging+prod only)
./scripts/new-team.sh <team-name>          # 4 envs
./scripts/new-team.sh <team-name> 2        # 2 envs
# After scaffolding, replace REPLACE_WITH_* placeholders in common.tfvars and envs/*.tfvars.

# Local validation against the Databricks root (must terraform init first with a backend-config,
# or use -backend=false to validate without contacting Azure):
cd terraform/databricks
terraform init -backend=false
terraform validate
terraform fmt -recursive ../

# Plan locally for one team/env (the CI does this via the workflow; you rarely need to):
cd terraform/databricks
terraform plan \
  -var-file=../../config/teams/<team>/common.tfvars \
  -var-file=../../config/teams/<team>/envs/<env>.tfvars
```

There is no top-level lint, build, or test script. CI runs `terraform fmt -check`, `terraform validate`, and `tflint` via `terraform-testing.yml`. There are no Go/Terratest harnesses in the repo.

## When adding a new team

The full sequence the workflow expects:
1. Run `./scripts/new-team.sh <slug>` (slug must match `^[a-z0-9][a-z0-9-]*[a-z0-9]$`).
2. Fill in `REPLACE_WITH_*` placeholders — subnet IDs, cost center.
3. Ensure the subnets and (typically) the resource group exist in Azure first.
4. Open a PR — the pipeline runs plan on every team × env. Once merged, trigger apply manually via the `Terraform Databricks` workflow's `Run workflow` button (dispatch from `develop` for dev/qa, from `main` for staging/prod — the latter still gated by the `databricks-staging` / `databricks-prod` GitHub Environments).

## When adding a new environment to an existing team

Just add `config/teams/<team>/envs/<new-env>.tfvars`. Then ensure:
- `<new-env>` is one of `dev|qa|staging|prod` (the `environment` variable validation rejects anything else).
- `config/global/subscriptions.json` has a mapping for the new env if it's not one of the existing four.
- A `databricks-<new-env>` GitHub Environment exists if it should require approval (only staging/prod do today).
