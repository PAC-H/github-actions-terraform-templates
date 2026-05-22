module "workspace" {
  source = "../modules/databricks-workspace"

  workspace_name      = "${var.team_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  public_subnet_id    = var.public_subnet_id
  private_subnet_id   = var.private_subnet_id
  compliance_profile  = var.compliance_profile
  sku                 = var.sku

  tags = merge(var.tags, {
    Environment = var.environment
    Team        = var.team_name
    ManagedBy   = "terraform"
  })
}
