environment = "staging"

resource_group_name = "rg-example-team-4env-staging-databricks"

public_subnet_id  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-network-staging/providers/Microsoft.Network/virtualNetworks/vnet-staging/subnets/snet-databricks-public-staging"
private_subnet_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-network-staging/providers/Microsoft.Network/virtualNetworks/vnet-staging/subnets/snet-databricks-private-staging"

compliance_profile = "enhanced"
