environment = "prod"

resource_group_name = "rg-team-name-prod-databricks"

public_subnet_id  = "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{public-subnet-name}"
private_subnet_id = "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{private-subnet-name}"

compliance_profile = "enhanced"
