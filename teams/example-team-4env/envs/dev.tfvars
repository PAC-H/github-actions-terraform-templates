environment = "dev"

resource_group_name = "rg-example-team-4env-dev-databricks"

public_subnet_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-dev/providers/Microsoft.Network/virtualNetworks/vnet-dev/subnets/snet-databricks-public-dev"
private_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-dev/providers/Microsoft.Network/virtualNetworks/vnet-dev/subnets/snet-databricks-private-dev"

compliance_profile = "standard"
