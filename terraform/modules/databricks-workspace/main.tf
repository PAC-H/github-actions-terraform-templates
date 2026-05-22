locals {
  location = "australiaeast"

  # Derive VNet ID and subnet names from the provided Azure resource IDs.
  # Subnet ID format: /subscriptions/{sub}/resourceGroups/{rg}/providers/
  #   Microsoft.Network/virtualNetworks/{vnet}/subnets/{name}
  public_subnet_name  = regex("/subnets/([^/]+)$", var.public_subnet_id)[0]
  private_subnet_name = regex("/subnets/([^/]+)$", var.private_subnet_id)[0]
  vnet_id             = regex("^(.*)/subnets/[^/]+$", var.public_subnet_id)[0]
}

# Validate that enhanced compliance requires premium SKU
resource "terraform_data" "compliance_sku_check" {
  lifecycle {
    precondition {
      condition     = !(var.compliance_profile == "enhanced" && var.sku != "premium")
      error_message = "compliance_profile 'enhanced' requires sku 'premium'."
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = local.location
  tags     = var.tags
}

resource "azurerm_network_security_group" "databricks" {
  name                = "nsg-${var.workspace_name}"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = var.public_subnet_id
  network_security_group_id = azurerm_network_security_group.databricks.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = var.private_subnet_id
  network_security_group_id = azurerm_network_security_group.databricks.id
}

resource "azurerm_databricks_workspace" "this" {
  name                        = var.workspace_name
  resource_group_name         = azurerm_resource_group.this.name
  location                    = local.location
  sku                         = var.sku
  managed_resource_group_name = "${var.resource_group_name}-managed"
  tags                        = var.tags

  custom_parameters {
    virtual_network_id                                   = local.vnet_id
    public_subnet_name                                   = local.public_subnet_name
    private_subnet_name                                  = local.private_subnet_name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
  }

  dynamic "enhanced_security_compliance" {
    for_each = var.compliance_profile == "enhanced" ? [1] : []
    content {
      automatic_cluster_update_enabled      = true
      compliance_security_profile_enabled   = true
      compliance_security_profile_standards = ["NONE"]
      enhanced_security_monitoring_enabled  = true
    }
  }

  # Prevent accidental destruction — especially important for workspaces with
  # enhanced compliance enabled, which cannot be downgraded without recreating.
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.public,
    azurerm_subnet_network_security_group_association.private,
  ]
}
