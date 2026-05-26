# GitHub Actions Terraform Templates

GitHub Actions workflows + Terraform templates for deploying Azure Databricks workspaces across multiple **teams** and **environments** (`dev` / `qa` / `staging` / `prod`), authenticated via Azure OIDC. Terraform state lives in Azure Blob Storage.

## Features

- **Azure OIDC authentication** — no client secrets
- **Multi-team, multi-environment** layout: each team gets its own folder under `config/teams/` with per-env tfvars
- **Per-env approval gates** via GitHub Environments (`databricks-staging`, `databricks-prod`)
- **Subscription routing** via `config/global/subscriptions.json` (`dev`+`qa` share one subscription, `staging`+`prod` share another)
- **Drift detection** across every team × env, weekly
- **State management** ops: unlock, list, show, remove, backup, restore
- **Compliance** scanning: `tflint` + `checkov` + Azure Policy queries
- **Utilities**: `tfupdate`, dependency graphs, targeted apply/destroy, imports
- **Static testing**: `terraform fmt -check`, `terraform validate`, `tflint`
- **Teams notifications** on apply / drift / failure

## Project structure

```
.
├── .github/
│   ├── workflows/
│   │   ├── databricks-workspace.yml      # Main deploy pipeline (plan + apply)
│   │   ├── terraform-drift-detection.yml # Weekly drift check, all team × env
│   │   ├── terraform-state-management.yml# Unlock/list/show/remove/backup/restore
│   │   ├── terraform-compliance.yml      # tflint + checkov + Azure Policy
│   │   ├── terraform-utilities.yml       # tfupdate, graph, target ops, imports
│   │   └── terraform-testing.yml         # fmt + validate + tflint
│   └── actions/
│       ├── setup-terraform/
│       ├── azure-login/
│       ├── teams-notification/
│       └── terraform-cache/
├── config/
│   ├── global/
│   │   ├── base.json                     # Terraform versions, runners, webhook, backup storage
│   │   └── subscriptions.json            # env → subscription-alias mapping
│   ├── teams/                            # Per-team tfvars (workspace today; +keyvault etc. later)
│   │   ├── _template/                    # Scaffolding source (skipped by workflows)
│   │   ├── example-team-2env/            # staging + prod
│   │   ├── example-team-4env/            # dev + qa + staging + prod
│   │   └── <team>/
│   │       ├── common.tfvars             # team-wide vars
│   │       └── envs/
│   │           ├── dev.tfvars
│   │           ├── qa.tfvars
│   │           ├── staging.tfvars
│   │           └── prod.tfvars
│   └── imports/
│       └── _template/                    # Per-env import templates for new teams
│           ├── dev-imports.json
│           ├── qa-imports.json
│           ├── staging-imports.json
│           └── prod-imports.json
├── terraform/
│   ├── databricks/                       # Root module — single root for all teams
│   └── modules/
│       └── databricks-workspace/         # Reusable Databricks workspace module
├── scripts/
│   └── new-team.sh                       # Scaffold a new team (2 or 4 envs)
├── CLAUDE.md
└── README.md
```

## Quick start

### 1. Azure prerequisites

- One Azure AD app registration **per subscription alias** (`dev-qa`, `staging-prod`), each with an OIDC federated credential for this repo.
- Each service principal needs `Contributor` (or equivalent) on the target subscription and `Storage Blob Data Contributor` on the state storage account.
- Pre-existing VNet + subnets in each subscription (the workspace module consumes their resource IDs; it does not create them).

### 2. GitHub repository secrets

```
AZURE_TENANT_ID

# dev-qa subscription pair
AZURE_CLIENT_ID_DEV_QA
AZURE_SUBSCRIPTION_DEV_QA
TF_STATE_STORAGE_ACCOUNT_DEV_QA
TF_STATE_RESOURCE_GROUP_DEV_QA

# staging-prod subscription pair
AZURE_CLIENT_ID_STAGING_PROD
AZURE_SUBSCRIPTION_STAGING_PROD
TF_STATE_STORAGE_ACCOUNT_STAGING_PROD
TF_STATE_RESOURCE_GROUP_STAGING_PROD

# optional
TEAMS_WEBHOOK_URL
```

The dynamic env-to-secret indirection is needed because GitHub Actions doesn't support `secrets[expression]` lookup — see the `Resolve subscription credentials` step in each workflow.

### 3. GitHub Environments

Create environments named **`databricks-staging`** and **`databricks-prod`** (Settings → Environments) with required reviewers. The deploy pipeline gates `staging`/`prod` applies on these; `dev`/`qa` auto-apply.

### 4. Scaffold a team

```bash
# 4-env layout (dev + qa + staging + prod) — default
./scripts/new-team.sh my-team

# 2-env layout (staging + prod only)
./scripts/new-team.sh my-team 2
```

Then edit `config/teams/my-team/common.tfvars` and `envs/*.tfvars` to replace every `REPLACE_WITH_*` placeholder (subnet IDs, cost center, etc.). Make sure the resource group and subnets named in the tfvars exist in Azure first.

### 5. Deploy

Open a PR against `develop` or `main` to run plan across the affected `{team, env}` matrix. Once merged, trigger apply manually via the workflow's `Run workflow` button.

`databricks-workspace.yml` jobs:

1. `detect-changes` — on PR, diffs against base to identify changed teams (module changes queue all teams); on dispatch, honours `team` / `environment` inputs (`all` to fan out).
2. `plan` — runs per `{team, env}` matrix entry against `terraform/databricks/` with both var-files.
3. `apply-lower` — applies `dev`/`qa`. Only fires on dispatch from `develop` or `main`.
4. `apply-upper` — applies `staging`/`prod`. Only fires on dispatch from `main`, gated by the `databricks-<env>` GitHub Environment.

PRs never trigger apply — both apply jobs check `github.event_name != 'pull_request'`.

## Workflows reference

### Databricks Workspace (`databricks-workspace.yml`)
Main deploy pipeline. Triggers on PRs (plan only) and `workflow_dispatch` (plan + apply). No push trigger — apply is manual. Builds a `{team, environment, subscription_alias}` matrix and runs plan, then apply gated by branch + GitHub Environment.

### Drift Detection (`terraform-drift-detection.yml`)
Weekly (Sundays 09:00 UTC) and on demand. Fans out across **every** `{team, env}` combo under `config/teams/`, runs `terraform plan -detailed-exitcode`, uploads drift reports and notifies Teams for any drift.

### State Management (`terraform-state-management.yml`)
Manual operations against a single `{team, environment}`:
- `unlock` — release a stuck state lock (requires `lock_id`)
- `list` — `terraform state list`
- `show` — `terraform state show <addr>`
- `remove` — `terraform state rm` with automatic pre-removal state backup
- `backup` — pull state and copy to the backup container (`storage.backup_account` in `base.json`)
- `restore` — overwrite state from a backup blob (requires `backup_name`)

A scheduled cron (Sundays 02:00 UTC) backs up every `{team, env}` automatically.

`staging` and `prod` slices gate on the `databricks-<env>` GitHub Environment for approval.

### Compliance (`terraform-compliance.yml`)
- PR trigger: scans every team affected by the changed files (module changes queue all teams).
- Manual dispatch: `team` + `environment` inputs (each accepts `all`).
- For each slice: `terraform plan -out`, then `tflint`, `checkov` on the plan JSON, and `az policy state list` against the resource group named in the env tfvars. Posts a per-slice summary comment on PRs.

### Utilities (`terraform-utilities.yml`)
Manual ops against a `{team, environment}`:
- `tfupdate` — bumps the `azurerm` provider in both `terraform/databricks/` and `terraform/modules/databricks-workspace/`; opens a PR on push events.
- `dependency-graph` — `terraform graph` rendered as SVG + PNG via Graphviz.
- `target-apply` / `target-destroy` — surgical `terraform apply`/`destroy` against `target_resources` (comma-separated).
- `import-individual` — single `terraform import` with pre-import state backup.
- `import-bulk` — bulk imports from `config/imports/<team>/<env>-imports.json` (skips resources already in state).
- `import-dry-run` — validate an imports file without touching state.

The bulk-import JSON shape:

```json
{
  "imports": [
    {
      "resource_address": "module.databricks_workspace.azurerm_databricks_workspace.this",
      "resource_id": "/subscriptions/.../resourceGroups/.../providers/Microsoft.Databricks/workspaces/..."
    }
  ]
}
```

Templates live under `config/imports/_template/`. Copy them to `config/imports/<your-team>/<env>-imports.json` and edit before running.

### Testing (`terraform-testing.yml`)
Static checks only — no Azure resources are created:
- `terraform fmt -check -recursive ./terraform`
- `terraform validate` on `terraform/databricks/` and `terraform/modules/databricks-workspace/` (using `-backend=false`)
- `tflint` on both

Triggers on `workflow_dispatch` and on pushes to `develop`/`main` that touch `terraform/**`.

## Reusable composite actions

```yaml
- uses: ./.github/actions/setup-terraform
  with:
    working_directory: terraform/databricks
    environment: dev
```

```yaml
- uses: azure/login@v2
  with:
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ steps.sub.outputs.sub_id }}
    client-id: ${{ steps.sub.outputs.client_id }}
```

```yaml
- uses: ./.github/actions/teams-notification
  with:
    webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
    status: success
    environment: "my-team / staging"
    message: "Apply succeeded"
```

## Local commands

```bash
# Scaffold a team
./scripts/new-team.sh my-team       # 4 envs (default)
./scripts/new-team.sh my-team 2     # 2 envs

# Format check
terraform fmt -check -recursive ./terraform

# Validate the root (no backend)
cd terraform/databricks
terraform init -backend=false
terraform validate

# Plan one team/env locally (assumes you've initted with a real backend)
terraform plan \
  -var-file=../../config/teams/<team>/common.tfvars \
  -var-file=../../config/teams/<team>/envs/<env>.tfvars
```

## Key invariants

- **`compliance_profile = "enhanced"` requires `sku = "premium"`** — enforced as a `precondition` on a `terraform_data` resource in `terraform/modules/databricks-workspace/main.tf` and rejected at apply by the provider. Enhanced compliance is one-way; downgrading requires recreating the workspace.
- **`prevent_destroy = true`** on `azurerm_databricks_workspace.this`. Removing a team or env from `config/teams/` will not destroy the workspace — the resource must be removed from state (or the lifecycle rule flipped) explicitly.
- **Subnets are pre-existing.** `public_subnet_id` / `private_subnet_id` in env tfvars are full Azure resource IDs; the module parses VNet ID + subnet names out of them.
- **`config/teams/_template/`** is the scaffolding source; the workflows skip any directory starting with `_`. Don't rename it.

## Security

- All authentication uses Azure OIDC — no stored client secrets.
- Per-subscription service principals (one for `dev-qa`, one for `staging-prod`). Each should hold only the roles it needs.
- `staging` / `prod` applies gate on a GitHub Environment with required reviewers.
- State containers should restrict to `Storage Blob Data Contributor` for the deploy SP, and `Reader` for everyone else.
- Apply self-hosted runners only — `runners.labels` in `config/global/base.json` controls this.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Workflow can't find secrets `AZURE_CLIENT_ID_*` | Repository or environment-level secrets not set, or env-level scoping prevents the resolve step from reading them. |
| Plan fails on `prevent_destroy` | Removing or renaming the team/env without first removing the workspace from state. |
| Compliance workflow's Azure Policy step is empty | `resource_group_name` in the env tfvars doesn't match a real RG, or the SP has no read permission on it. |
| Drift detection always reports drift | Provider version drift, or out-of-band changes made in the Azure portal. |
| `terraform init` fails with `BlobNotFound` | First run for that team/env — that's expected; the plan job will create the state blob on first apply. |
| Import workflow can't see `config/imports/.../*.json` | Path passed in `import_config_file` is wrong, or the file is not committed to the branch you triggered against. |

## License

MIT — see [LICENSE](LICENSE).
