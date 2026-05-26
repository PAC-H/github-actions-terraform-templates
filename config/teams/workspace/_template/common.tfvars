# Team-wide Terraform variables applied to every environment.
# Merged with envs/<env>.tfvars at plan time.

team_name = "team-name"

# 'premium' is required if any environment uses compliance_profile = "enhanced".
# 'standard' is sufficient when all envs use compliance_profile = "standard".
sku = "premium"

tags = {
  team        = "team-name"
  cost_center = "00000"
}
