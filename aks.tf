resource "azurerm_kubernetes_cluster" "k8s" {
  count               = var.resource_count
  name                = local.cluster_names[count.index]
  resource_group_name = azurerm_resource_group.k8s-rg[count.index].name
  location            = azurerm_resource_group.k8s-rg[count.index].location

  dns_prefix = var.dns_prefix
  kubernetes_version = "1.27.7"

  default_node_pool {
    name = "default"
    node_count = var.agent_count
    vm_size = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.node-subnet[count.index].id
    pod_subnet_id = azurerm_subnet.pod-subnet[count.index].id
  }
  # service_principal {
  #   client_id = var.client_id
  #   client_secret = var.client_secret
  # }
  identity {
    type = "SystemAssigned"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.network[count.index].id
  }

  network_profile {
    load_balancer_sku = "standard"
    network_plugin = "azure"
    outbound_type = "loadBalancer"
  }
  tags = {
    Environment = "Development"
    delegation = "trial-01"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "example1" {
  name = "example1"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s[0].id
  vm_size = "Standard_DS2_v2"
  node_count = 1

  vnet_subnet_id = azurerm_subnet.node-subnet[0].id 
  pod_subnet_id = azurerm_subnet.pod-subnet[0].id
}
