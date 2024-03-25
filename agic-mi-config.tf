data "azurerm_resource_group" "mc_rg" {
  count = var.resource_count
  name = azurerm_kubernetes_cluster.k8s[count.index].node_resource_group
  depends_on = [ azurerm_resource_group.k8s-rg ]
}

data "azurerm_user_assigned_identity" "auto_created_agic_mi" {
  count = var.resource_count
  name  = "ingressapplicationgateway-${azurerm_kubernetes_cluster.k8s[count.index].name}"
  resource_group_name = data.azurerm_resource_group.mc_rg[count.index].name
}

resource "azurerm_role_assignment" "assign_contributor_agic" {
  count                = var.resource_count
  scope                = azurerm_application_gateway.network[count.index].id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_user_assigned_identity.auto_created_agic_mi[count.index].principal_id
}

resource "azurerm_role_assignment" "assign_reader_appgw_rg" {
  count                = var.resource_count
  scope                = azurerm_resource_group.k8s-rg[count.index].id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_user_assigned_identity.auto_created_agic_mi[count.index].principal_id
}

# resource "azurerm_role_assignment" "assign_contributor_mc_k8s_rg" {
#   scope = data.azurerm_resource_group.mc_rg.id
#   role_definition_name = "Contributor"
#   principal_id         = data.azurerm_user_assigned_identity.auto_created_agic_mi.principal_id

#   depends_on = [ azurerm_kubernetes_cluster.k8s ]
# }

# resource "azurerm_role_assignment" "assign_network_contributor_agic_rg" {
#   scope = azurerm_subnet.ingress-appgateway-subnet.id
#   role_definition_name = "Network Contributor"
#   principal_id         = data.azurerm_user_assigned_identity.auto_created_agic_mi.principal_id
# }