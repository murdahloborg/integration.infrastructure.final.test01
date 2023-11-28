variable "az_subscription_name" {
  description = "az subscription short name: dev, test or prod"
  type        = string
}

variable "az_env_name" {
  description = "az environment name: pim or d365 or others"
  type        = string
}

variable "az_env_sufix" {
  description = "az environment sufix: 001 and so on"
  type        = string
}

variable "az_region" {
  description = "az region"
  type        = string
  default = "westeurope"
}

variable "env_number" {
  description = "Environment number"
  type        = number
}
