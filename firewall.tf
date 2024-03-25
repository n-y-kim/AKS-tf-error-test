resource "azurerm_public_ip" "example" {
    count = var.resource_count
    name                = "fw-pip-${count.index}"
    location            = var.rg-location
    resource_group_name = azurerm_resource_group.k8s-rg[count.index].name
    allocation_method   = "Static"
    sku                 = "Standard"
}

resource "azurerm_firewall" "example" {
    count              = var.resource_count
    name                = "firewall-${count.index}"
    location            = var.rg-location
    resource_group_name = azurerm_resource_group.k8s-rg[count.index].name
    sku_name = "AZFW_VNet"
    sku_tier = "Standard"

    ip_configuration {
        name                 = "configuration"
        subnet_id            = azurerm_subnet.firewall-subnet[count.index].id
        public_ip_address_id = azurerm_public_ip.example[count.index].id
    }
}