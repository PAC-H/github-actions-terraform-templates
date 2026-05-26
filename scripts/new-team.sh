#!/usr/bin/env bash
# Usage: ./scripts/new-team.sh <team-name> [2|4]
#
# Scaffolds a new team folder under teams/<team-name>/ with:
#   common.tfvars     — team-wide Terraform variables
#   envs/<env>.tfvars — per-environment Terraform variables (one file per env)
#
# The set of environments is inferred from the filenames in envs/, so just
# add or remove a file there to add or remove an environment.
#
# Pass 2 for a 2-environment team (staging + prod only).
# Pass 4 (default) for a 4-environment team (dev + qa + staging + prod).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEAM_NAME="${1:-}"
ENV_COUNT="${2:-4}"

if [[ -z "$TEAM_NAME" ]]; then
  echo "Usage: $0 <team-name> [2|4]"
  echo "  team-name  Lowercase slug (letters, numbers, hyphens only)"
  echo "  2|4        Number of environments (default: 4)"
  exit 1
fi

if ! echo "$TEAM_NAME" | grep -qE '^[a-z0-9][a-z0-9-]*[a-z0-9]$'; then
  echo "Error: team-name must be lowercase alphanumeric with hyphens (no leading/trailing hyphens)"
  exit 1
fi

if [[ "$ENV_COUNT" != "2" && "$ENV_COUNT" != "4" ]]; then
  echo "Error: environment count must be 2 or 4"
  exit 1
fi

DEST_DIR="$REPO_ROOT/teams/$TEAM_NAME"

if [[ -d "$DEST_DIR" ]]; then
  echo "Error: teams/$TEAM_NAME already exists. Edit the existing files directly."
  exit 1
fi

if [[ "$ENV_COUNT" == "4" ]]; then
  ENV_LIST=(dev qa staging prod)
else
  ENV_LIST=(staging prod)
fi

mkdir -p "$DEST_DIR/envs"

cat > "$DEST_DIR/common.tfvars" <<TFVARS
team_name = "${TEAM_NAME}"

# 'premium' is required if any environment uses compliance_profile = "enhanced".
sku = "premium"

tags = {
  team        = "${TEAM_NAME}"
  cost_center = "REPLACE_WITH_COST_CENTER"
}
TFVARS

for env in "${ENV_LIST[@]}"; do
  case "$env" in
    dev|qa)        profile="standard" ;;
    staging|prod)  profile="enhanced" ;;
  esac

  cat > "$DEST_DIR/envs/${env}.tfvars" <<TFVARS
environment = "${env}"

resource_group_name = "rg-${TEAM_NAME}-${env}-databricks"

public_subnet_id  = "REPLACE_WITH_${env^^}_PUBLIC_SUBNET_ID"
private_subnet_id = "REPLACE_WITH_${env^^}_PRIVATE_SUBNET_ID"

compliance_profile = "${profile}"
TFVARS
done

echo "✓ Created teams/${TEAM_NAME}/ (${ENV_COUNT} environments)"
echo "    common.tfvars"
for env in "${ENV_LIST[@]}"; do
  echo "    envs/${env}.tfvars"
done
echo ""
echo "Next steps:"
echo "  1. Replace REPLACE_WITH_* placeholders in common.tfvars and envs/*.tfvars"
echo "  2. Ensure subnets are pre-provisioned in Azure before applying"
echo "  3. Push the files to trigger the CI/CD pipeline (or run manually via workflow_dispatch)"
echo ""
echo "Reminder:"
echo "  • dev/qa environments auto-apply on merge to develop/main"
echo "  • staging/prod require manual approval via GitHub environment gate"
echo "  • compliance_profile: enhanced is a one-way change — cannot be downgraded"
