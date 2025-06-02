output "resource_group_name" {
  description = "Name of the created resource group"
  value       = module.example.resource_group_name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = module.example.resource_group_id
}

output "location" {
  description = "Location of the resource group"
  value       = module.example.location
} 