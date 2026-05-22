terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.30.0"
    }
  }

  # All backend arguments are supplied via -backend-config flags at init time.
  # Key convention: teams/{team_name}/{environment}.tfstate
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  use_oidc        = true
  subscription_id = var.subscription_id
}
