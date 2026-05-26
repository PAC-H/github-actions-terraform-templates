environment = "qa"

resource_group_name = "rg-example-team-4env-qa-databricks"

public_subnet_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-qa/providers/Microsoft.Network/virtualNetworks/vnet-qa/subnets/snet-databricks-public-qa"
private_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-qa/providers/Microsoft.Network/virtualNetworks/vnet-qa/subnets/snet-databricks-private-qa"

compliance_profile = "standard"
