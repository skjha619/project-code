terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.90.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  default = "eastus"
}


# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-bluegreen"
  location = var.location
}

# ACR Registry
resource "azurerm_container_registry" "acr" {
  name                = "acr365s35"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"

  # Enable admin user so we can get credentials
  admin_enabled = true
}

# Container App Environment
resource "azurerm_container_app_environment" "env" {
  name                = "aca-env"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Container App with ACR login
resource "azurerm_container_app" "app" {
  name                         = "myapp"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id

  revision_mode = "Multiple"

  # Provide registry credentials
  secret {
    name  = "acr-pwd"
    value = azurerm_container_registry.acr.admin_password
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-pwd"
  }

  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name  = "app-container"
      image = var.image
      cpu    = 0.5
      memory = "1.0Gi"
    }

    revision_suffix = var.revision_suffix
  }
}

output "container_app_fqdn" {
  value = azurerm_container_app.app.ingress[0].fqdn
}
