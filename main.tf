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
      version = ">= 1.10.0"
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

resource "azurerm_resource_group" "rg_env" {
  name     = "rg-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  location = var.az_region
}

resource "azurerm_network_security_group" "nsg_env" {
  name                = "nsg-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  location            = azurerm_resource_group.rg_env.location
  resource_group_name = azurerm_resource_group.rg_env.name
  tags = {
    "costcenter" = "102040000"
  }
}

resource "azapi_resource" "snet_env" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2023-04-01"
  name      = "snet-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  parent_id = data.azurerm_virtual_network.vnet_int.id

  body = jsonencode({
    properties = {

      addressPrefix = "10.0.${50 + var.env_number * 2}.0/23"

      networkSecurityGroup = {
        id = azurerm_network_security_group.nsg_env.id
      }

      delegations = [
        {
          name = "Microsoft.Appenvironments"
          properties = {
            serviceName = "Microsoft.App/environments"
          }
        }
      ]
      serviceEndpoints = []
    }
  })

  depends_on = [
    azurerm_network_security_group.nsg_env
  ]
}

resource "azurerm_subnet_nat_gateway_association" "snet_nat_link_env" {
  subnet_id      = azapi_resource.snet_env.id
  nat_gateway_id = data.azurerm_nat_gateway.ngw_int.id
}

resource "azapi_resource" "cae_env" {
  type      = "Microsoft.App/managedEnvironments@2023-05-01"
  name      = "cae-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  parent_id = azurerm_resource_group.rg_env.id
  location  = azurerm_resource_group.rg_env.location

  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = data.azurerm_log_analytics_workspace.law_int.workspace_id,
          sharedKey  = data.azurerm_log_analytics_workspace.law_int.primary_shared_key
        }
      }

      vnetConfiguration = {
        infrastructureSubnetId = azapi_resource.snet_env.id

        internal = false
      }
      workloadProfiles = [
        {
          "workloadProfileType" : "Consumption",
          "name" : "Consumption"
        }
      ]
    }
  })

  depends_on = [
    azurerm_resource_group.rg_env, azapi_resource.snet_env
  ]
  response_export_values  = ["properties.defaultDomain", "properties.staticIp", "properties.customDomainConfiguration.customDomainVerificationId"]
  ignore_missing_property = true
}

resource "azurerm_container_app_environment_certificate" "ca_certificate_domain_env" {
  name                         = "ca-cert-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  container_app_environment_id = azapi_resource.cae_env.id
  certificate_blob_base64      = data.azurerm_key_vault_secret.cert_int_domain.value
  certificate_password         = ""
}
