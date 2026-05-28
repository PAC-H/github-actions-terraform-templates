variable "subscription_id" {
  description = "Azure subscription ID for this environment (populated by CI/CD from subscriptions.json)"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "subscription_id must be a UUID (e.g. 00000000-0000-0000-0000-000000000000)."
  }
}

variable "team_name" {
  description = "Team slug — must match the folder name under config/teams/ (from common.tfvars)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.team_name))
    error_message = "team_name must be lowercase alphanumeric with hyphens, no leading/trailing hyphens."
  }
}

variable "environment" {
  description = "Environment name: dev, qa, staging, or prod (from envs/<env>.tfvars)"
  type        = string

  # Keep this list in sync with the keys under .environments in
  # config/global/subscriptions.json — that file is the source of truth for
  # tier metadata (subscription + requires_approval), but Terraform can't read
  # JSON at validation time, so the allowed set is duplicated here.
  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, staging, prod."
  }
}

variable "resource_group_name" {
  description = "Azure resource group name for the workspace (from envs/<env>.tfvars)"
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "resource_group_name must be 1-90 characters."
  }

  validation {
    condition     = !can(regex("REPLACE_WITH", var.resource_group_name))
    error_message = "resource_group_name still contains a REPLACE_WITH placeholder — fill it in before applying."
  }
}

variable "public_subnet_id" {
  description = "Azure resource ID of the pre-existing public subnet (from envs/<env>.tfvars)"
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.public_subnet_id))
    error_message = "public_subnet_id must be a full Azure subnet resource ID: /subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}."
  }
}

variable "private_subnet_id" {
  description = "Azure resource ID of the pre-existing private subnet (from envs/<env>.tfvars)"
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.private_subnet_id))
    error_message = "private_subnet_id must be a full Azure subnet resource ID: /subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}."
  }

  validation {
    condition     = var.private_subnet_id != var.public_subnet_id
    error_message = "private_subnet_id and public_subnet_id must reference different subnets."
  }
}

variable "compliance_profile" {
  description = "Databricks compliance profile: standard or enhanced"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "enhanced"], var.compliance_profile)
    error_message = "compliance_profile must be 'standard' or 'enhanced'."
  }
}

variable "sku" {
  description = "Databricks workspace SKU: standard or premium"
  type        = string
  default     = "premium"

  validation {
    condition     = contains(["standard", "premium"], var.sku)
    error_message = "sku must be 'standard' or 'premium'."
  }
}

variable "tags" {
  description = "Additional tags to merge onto all resources"
  type        = map(string)
  default     = {}
}

# Cross-variable invariant: 'enhanced' compliance requires the 'premium' SKU.
# Emits a warning (not an error) because check blocks cannot fail a plan in
# Terraform <1.9. The provider will reject the combination at apply time.
check "enhanced_compliance_requires_premium_sku" {
  assert {
    condition     = var.compliance_profile != "enhanced" || var.sku == "premium"
    error_message = "compliance_profile = \"enhanced\" requires sku = \"premium\"."
  }
}
