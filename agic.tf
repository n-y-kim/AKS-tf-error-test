resource "azurerm_public_ip" "ag-pip" {
  count              = var.resource_count
  name                = "ag-pip-${count.index}"
  resource_group_name = azurerm_resource_group.k8s-rg[count.index].name
  location            = azurerm_resource_group.k8s-rg[count.index].location
  allocation_method   = "Static"
  sku = "Standard"
}

# since these variables are re-used - a locals block makes this more maintainable

locals {
  backend_address_pool_names      = [for i in azurerm_virtual_network.k8s-vnet : "${i.name}-beap"]
  frontend_port_names             = [for i in azurerm_virtual_network.k8s-vnet : "${i.name}-feport"]
  http_setting_names              = [for i in azurerm_virtual_network.k8s-vnet : "${i.name}-be-htst"]
  listener_names                  = [for i in azurerm_virtual_network.k8s-vnet : "${i.name}-httplstn"]
  request_routing_rule_names      = [for i in azurerm_virtual_network.k8s-vnet : "${i.name}-rqrt"]
 
  frontend_public_ip_configuration_name = "public-ip-configuration"
  frontend_private_ip_configuration_name = "private-ip-configuration"
}

# resource "azurerm_user_assigned_identity" "agic_identity" {
#   name                = "agic-identity"
#   location = azurerm_resource_group.k8s-rg.location
#   resource_group_name = azurerm_resource_group.k8s-rg.name
# }

resource "azurerm_application_gateway" "network" {
  count               = var.resource_count
  name                = "appgw-${count.index}"
  resource_group_name = azurerm_resource_group.k8s-rg[count.index].name
  location            = azurerm_resource_group.k8s-rg[count.index].location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.ingress-appgateway-subnet[count.index].id
  }

  frontend_port {
    name = local.frontend_port_names[count.index]
    port = 80
  }

  # identity {
  #   type = "UserAssigned"
  #   identity_ids  = [azurerm_user_assigned_identity.agic_identity.id]
  # }

  frontend_ip_configuration {
    name                 = local.frontend_public_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.ag-pip[count.index].id
  }

  # frontend_ip_configuration {
  #   name                 = local.frontend_private_ip_configuration_name
  #   private_ip_address   = "172.0.34.9"
  #   subnet_id            = azurerm_subnet.ingress-appgateway-subnet[count.index].id
  #   private_ip_address_allocation = "Static"
  # }

  backend_address_pool {
    name = local.backend_address_pool_names[count.index]

  }

  backend_http_settings {
    name                  = local.http_setting_names[count.index]
    cookie_based_affinity = "Disabled"
    # path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    # request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_names[count.index]
    frontend_ip_configuration_name = local.frontend_public_ip_configuration_name
    frontend_port_name             = local.frontend_port_names[count.index]
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_names[count.index]
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_names[count.index]
    backend_address_pool_name  = local.backend_address_pool_names[count.index]
    backend_http_settings_name = local.http_setting_names[count.index]
  }
}