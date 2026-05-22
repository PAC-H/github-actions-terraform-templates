#!/usr/bin/env bash
# Usage: ./scripts/new-team.sh <team-name> [2|4]
#
# Scaffolds a new team.yaml under teams/<team-name>/ from the template.
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
  echo "Error: teams/$TEAM_NAME already exists. Edit the existing team.yaml directly."
  exit 1
fi

mkdir -p "$DEST_DIR"

if [[ "$ENV_COUNT" == "4" ]]; then
  ENVIRONMENTS="[dev, qa, staging, prod]"
  ENV_BLOCKS=$(cat <<YAML

azure:
  per_env:
    dev:
      resource_group_name: "rg-${TEAM_NAME}-dev-databricks"
      public_subnet_id: "REPLACE_WITH_DEV_PUBLIC_SUBNET_ID"
      private_subnet_id: "REPLACE_WITH_DEV_PRIVATE_SUBNET_ID"
      compliance_profile: standard

    qa:
      resource_group_name: "rg-${TEAM_NAME}-qa-databricks"
      public_subnet_id: "REPLACE_WITH_QA_PUBLIC_SUBNET_ID"
      private_subnet_id: "REPLACE_WITH_QA_PRIVATE_SUBNET_ID"
      compliance_profile: standard

    staging:
      resource_group_name: "rg-${TEAM_NAME}-staging-databricks"
      public_subnet_id: "REPLACE_WITH_STAGING_PUBLIC_SUBNET_ID"
      private_subnet_id: "REPLACE_WITH_STAGING_PRIVATE_SUBNET_ID"
      compliance_profile: enhanced

    prod:
      resource_group_name: "rg-${TEAM_NAME}-prod-databricks"
      public_subnet_id: "REPLACE_WITH_PROD_PUBLIC_SUBNET_ID"
      private_subnet_id: "REPLACE_WITH_PROD_PRIVATE_SUBNET_ID"
      compliance_profile: enhanced
YAML
)
else
  ENVIRONMENTS="[staging, prod]"
  ENV_BLOCKS=$(cat <<YAML

azure:
  per_env:
    staging:
      resource_group_name: "rg-${TEAM_NAME}-staging-databricks"
      public_subnet_id: "REPLACE_WITH_STAGING_PUBLIC_SUBNET_ID"
      private_subnet_id: "REPLACE_WITH_STAGING_PRIVATE_SUBNET_ID"
      compliance_profile: enhanced

    prod:
      resource_group_name: "rg-${TEAM_NAME}-prod-databricks"
      public_subnet_id: "REPLACE_WITH_PROD_PUBLIC_SUBNET_ID"
      private_subnet_id: "REPLACE_WITH_PROD_PRIVATE_SUBNET_ID"
      compliance_profile: enhanced
YAML
)
fi

cat > "$DEST_DIR/team.yaml" <<YAML
name: ${TEAM_NAME}
display_name: "REPLACE_WITH_DISPLAY_NAME"
contact: "REPLACE_WITH_TEAM_EMAIL"

environments: ${ENVIRONMENTS}

databricks:
  sku: premium
  tags:
    team: ${TEAM_NAME}
    cost_center: "REPLACE_WITH_COST_CENTER"
${ENV_BLOCKS}
YAML

echo "✓ Created teams/${TEAM_NAME}/team.yaml (${ENV_COUNT} environments)"
echo ""
echo "Next steps:"
echo "  1. Edit teams/${TEAM_NAME}/team.yaml and replace all REPLACE_WITH_* placeholders"
echo "  2. Ensure subnets are pre-provisioned in Azure before applying"
echo "  3. Push the file to trigger the CI/CD pipeline (or run manually via workflow_dispatch)"
echo ""
echo "Reminder:"
echo "  • dev/qa environments auto-apply on merge to develop/main"
echo "  • staging/prod require manual approval via GitHub environment gate"
echo "  • compliance_profile: enhanced is a one-way change — cannot be downgraded"
