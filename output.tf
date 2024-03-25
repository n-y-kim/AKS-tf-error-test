output "application_gateway_id" {
    description = "ID of app gateway"
    value       = [for i in azurerm_application_gateway.network : i.id]
}