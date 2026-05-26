environment = "dev"

resource_group_name = "rg-team-name-dev-databricks"

# Full Azure resource IDs of the pre-existing subnets.
# This module performs VNet injection — it does NOT create VNets or subnets.
public_subnet_id  = "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{public-subnet-name}"
private_subnet_id = "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{private-subnet-name}"

# 'enhanced' is a one-way change — workspace must be recreated to downgrade.
compliance_profile = "standard"
