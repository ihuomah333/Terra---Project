terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.12.0"
    }
  }
}

provider "azurerm" {
  features {}

  # Subscription ID (optional)
  subscription_id = "a57a67df-8e10-4809-b5bf-5038c3608ed1"
}

resource "azurerm_resource_group" "azure_RGP" {
  name     = "RGP"
  location = "Canada Central"
}

resource "azurerm_virtual_network" "azure_vnet" {
  name                = "Vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azure_RGP.location
  resource_group_name = azurerm_resource_group.azure_RGP.name
}

resource "azurerm_subnet" "azure_subnet" {
  name                 = "myprsub"
  resource_group_name  = azurerm_resource_group.azure_RGP.name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name  # Corrected reference
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "azure_NIC" {
  name                = "new-nic-nic"
  location            = azurerm_resource_group.azure_RGP.location
  resource_group_name = azurerm_resource_group.azure_RGP.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azure_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "azure_vm" {
  name                = "myvm"
  resource_group_name = azurerm_resource_group.azure_RGP.name
  location            = azurerm_resource_group.azure_RGP.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.azure_NIC.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
