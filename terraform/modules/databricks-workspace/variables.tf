variable "workspace_name" {
  description = "Name of the Databricks workspace"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group to create for the Databricks workspace"
  type        = string
}

variable "public_subnet_id" {
  description = "Azure resource ID of the pre-existing public subnet for VNet injection"
  type        = string
}

variable "private_subnet_id" {
  description = "Azure resource ID of the pre-existing private subnet for VNet injection"
  type        = string
}

variable "compliance_profile" {
  description = "Databricks compliance profile: 'standard' or 'enhanced'. Enhanced requires premium SKU and is irreversible."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "enhanced"], var.compliance_profile)
    error_message = "compliance_profile must be 'standard' or 'enhanced'."
  }
}

variable "sku" {
  description = "Databricks workspace SKU: 'standard' or 'premium'. Enhanced compliance profile requires 'premium'."
  type        = string
  default     = "premium"

  validation {
    condition     = contains(["standard", "premium", "trial"], var.sku)
    error_message = "sku must be 'standard', 'premium', or 'trial'."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
