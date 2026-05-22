variable "subscription_id" {
  description = "Azure subscription ID for this environment (populated by CI/CD from subscriptions.json)"
  type        = string
}

variable "team_name" {
  description = "Team slug (must match the folder name under teams/)"
  type        = string
}

variable "environment" {
  description = "Environment name: dev, qa, staging, or prod"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, staging, prod."
  }
}

variable "resource_group_name" {
  description = "Azure resource group name for the workspace (from team.yaml azure.per_env.<env>.resource_group_name)"
  type        = string
}

variable "public_subnet_id" {
  description = "Azure resource ID of the pre-existing public subnet (from team.yaml)"
  type        = string
}

variable "private_subnet_id" {
  description = "Azure resource ID of the pre-existing private subnet (from team.yaml)"
  type        = string
}

variable "compliance_profile" {
  description = "Databricks compliance profile: standard or enhanced"
  type        = string
  default     = "standard"
}

variable "sku" {
  description = "Databricks workspace SKU: standard or premium"
  type        = string
  default     = "premium"
}

variable "tags" {
  description = "Additional tags to merge onto all resources"
  type        = map(string)
  default     = {}
}
