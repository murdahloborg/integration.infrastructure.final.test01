terraform {
  required_version = ">= 1.5.0"
  backend "azurerm" {
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.68.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_environment" {
  name     = "rg-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  location = var.az_region
}


