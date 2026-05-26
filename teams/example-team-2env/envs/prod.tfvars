environment = "prod"

resource_group_name = "rg-example-team-2env-prod-databricks"

public_subnet_id  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-databricks-public-prod-2env"
private_subnet_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-databricks-private-prod-2env"

compliance_profile = "enhanced"
