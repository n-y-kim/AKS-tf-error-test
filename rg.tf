resource "azurerm_resource_group" "k8s-rg" {
  count    = var.resource_count
  name     = "aks-rg-${count.index}"
  location = var.rg-location
}

resource "azurerm_virtual_network" "k8s-vnet" {
  count = var.resource_count
  name                = "k8s-vnet"
  resource_group_name = azurerm_resource_group.k8s-rg[count.index].name
  location            = azurerm_resource_group.k8s-rg[count.index].location
  address_space       = ["172.0.0.0/16"]
}

resource "azurerm_subnet" "node-subnet" {
  count = var.resource_count
  name                 = "node-subnet"
  resource_group_name  = azurerm_resource_group.k8s-rg[count.index].name
  virtual_network_name = azurerm_virtual_network.k8s-vnet[count.index].name
  address_prefixes     = ["172.0.32.0/24"]
}

resource "azurerm_subnet" "pod-subnet" {
  count = var.resource_count
  name                 = "pod-subnet"
  resource_group_name  = azurerm_resource_group.k8s-rg[count.index].name
  virtual_network_name = azurerm_virtual_network.k8s-vnet[count.index].name
  address_prefixes     = ["172.0.48.0/20"]

  delegation {
    name = "aks-delegation"

    service_delegation {
        actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
          ]
        name    = "Microsoft.ContainerService/managedClusters"
      }
  }
}

resource "azurerm_subnet" "ingress-appgateway-subnet" {
    count = var.resource_count
    name = "ingress-appgateway-subnet"
    resource_group_name = azurerm_resource_group.k8s-rg[count.index].name
    virtual_network_name = azurerm_virtual_network.k8s-vnet[count.index].name
    address_prefixes = ["172.0.34.0/24"]
}

resource "azurerm_subnet" "firewall-subnet" {
    count = var.resource_count
    name = "AzureFirewallSubnet"
    resource_group_name = azurerm_resource_group.k8s-rg[count.index].name
    virtual_network_name = azurerm_virtual_network.k8s-vnet[count.index].name
    address_prefixes = ["172.0.35.0/26"]
}

resource "azurerm_route_table" "route-table" {
  count = var.resource_count
  name                          = "example-route-table"
  location                      = var.rg-location
  resource_group_name           = azurerm_resource_group.k8s-rg[count.index].name
  disable_bgp_route_propagation = false

  route {
    name = "fw-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.example[count.index].ip_configuration[0].private_ip_address
  }

  route {
    name = "default-route"
    address_prefix = "${azurerm_public_ip.example[count.index].ip_address}/32"
    next_hop_type = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "example" {
  count = var.resource_count
  route_table_id = azurerm_route_table.route-table[count.index].id
  subnet_id = azurerm_subnet.node-subnet[count.index].id
}