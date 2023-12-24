provider "azurerm" {
  skip_provider_registration = true 
  features {}
}


variable "prefix" {
  default = "tfvmex"
}

resource "azurerm_resource_group" "sonarqube" {
  name     = "${var.prefix}-resources"
  location = "France Central"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.sonarqube.location
  resource_group_name = azurerm_resource_group.sonarqube.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.sonarqube.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.sonarqube.location
  resource_group_name = azurerm_resource_group.sonarqube.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.sonarqube.location
  resource_group_name   = azurerm_resource_group.sonarqube.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "khalil"
    admin_username = "khalil"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        key_data = file("/home/khalil/.ssh/azure_app_rsa.pub") 
        path = "/home/khalil/.ssh/authorized_keys"
    }
  }
  provisioner "remote-exec" {
    inline = [
      " chmod +x ./install_docker.sh ",    
      " ./install-docker.sh "              
    ]
  }
  tags = {
    environment = "testing"
  }
}