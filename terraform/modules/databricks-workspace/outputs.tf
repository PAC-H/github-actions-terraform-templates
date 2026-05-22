output "workspace_url" {
  description = "URL of the Databricks workspace"
  value       = "https://${azurerm_databricks_workspace.this.workspace_url}"
}

output "workspace_id" {
  description = "Azure resource ID of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.id
}

output "workspace_databricks_id" {
  description = "Databricks-internal numeric workspace ID"
  value       = azurerm_databricks_workspace.this.workspace_id
}

output "resource_group_id" {
  description = "Azure resource ID of the workspace resource group"
  value       = azurerm_resource_group.this.id
}
