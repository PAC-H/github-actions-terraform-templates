output "workspace_url" {
  description = "URL of the Databricks workspace"
  value       = module.workspace.workspace_url
}

output "workspace_id" {
  description = "Azure resource ID of the Databricks workspace"
  value       = module.workspace.workspace_id
}

output "workspace_databricks_id" {
  description = "Databricks-internal numeric workspace ID"
  value       = module.workspace.workspace_databricks_id
}

output "resource_group_id" {
  description = "Azure resource ID of the workspace resource group"
  value       = module.workspace.resource_group_id
}
