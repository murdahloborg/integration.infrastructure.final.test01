resource "azurerm_dns_cname_record" "dns_int_cname_d365-consumer" {
  name                = "ca-d365-consumer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  zone_name           = data.azurerm_dns_zone.dns_int.name
  resource_group_name = data.azurerm_dns_zone.dns_int.resource_group_name
  ttl                 = 300
  record              = "anewapp.${jsondecode(azapi_resource.cae_env.output).properties.defaultDomain}"
}


resource "azurerm_dns_txt_record" "dns_int_txt_d365-consumer" {
  name                = "asuid.ca-d365-consumer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  zone_name           = data.azurerm_dns_zone.dns_int.name
  resource_group_name = data.azurerm_dns_zone.dns_int.resource_group_name
  ttl                 = 300

  record {
    value = jsondecode(azapi_resource.cae_env.output).properties.customDomainConfiguration.customDomainVerificationId
  }
}

resource "azapi_resource" "containerapp_d365-consumer" {
  type      = "Microsoft.App/containerApps@2023-05-01"
  name      = "ca-d365-consumer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  parent_id = azurerm_resource_group.rg_env.id
  location  = azurerm_resource_group.rg_env.location
 
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.cae_env.id
      configuration = {
        ingress = {
          external : true,
          targetPort : 80

          customDomains = [
            {
              bindingType = "SniEnabled"
              certificateId = azurerm_container_app_environment_certificate.ca_certificate_domain_env.id
              name = "ca-d365-consumer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}.${data.azurerm_dns_zone.dns_int.name}"
            }
          ]
        },
 
      }
      template = {
        containers = [
          {
            image = "${var.d365-consumer_image}"
            name  = "d365-consumer"
            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }
          }
        ]
        scale = {
          minReplicas = 1,
          maxReplicas = 1
        }
      }
    }
 
  })
  depends_on = [
    azapi_resource.cae_env, azurerm_dns_cname_record.dns_int_cname_ca_name, azurerm_dns_txt_record.dns_int_txt_ca_name
  ]
}