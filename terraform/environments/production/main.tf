terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.30.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
  resource_provider_registrations = "none"
}

# Example resource group using the module
module "example" {
  source = "../../modules/example"
  
  resource_group_name = var.resource_group_name
  location           = var.location
  environment        = "production"
  tags               = var.tags
} 