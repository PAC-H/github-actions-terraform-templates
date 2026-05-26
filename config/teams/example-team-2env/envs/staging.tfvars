environment = "staging"

resource_group_name = "rg-example-team-2env-staging-databricks"

public_subnet_id  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-network-staging/providers/Microsoft.Network/virtualNetworks/vnet-staging/subnets/snet-databricks-public-staging-2env"
private_subnet_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-network-staging/providers/Microsoft.Network/virtualNetworks/vnet-staging/subnets/snet-databricks-private-staging-2env"

compliance_profile = "enhanced"
