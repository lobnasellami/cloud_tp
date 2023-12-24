provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

resource "azurerm_resource_group" "projet-devops" {
  name     = "projet-devops"
  location = "France central"
}

resource "azurerm_kubernetes_cluster" "projet-devops-cluser-aks" {
  name                = "projet-devops-cluser-aks"
  location            = azurerm_resource_group.projet-devops.location
  resource_group_name = azurerm_resource_group.projet-devops.name
  http_application_routing_enabled = true
  dns_prefix          = "exampleaks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "test"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.projet-devops-cluser-aks.kube_config.0.client_certificate
  sensitive = true
}

