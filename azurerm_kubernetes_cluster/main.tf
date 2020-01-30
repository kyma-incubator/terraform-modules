provider "azurerm" {
  version         = "~>1.5"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

terraform {
  required_version = ">= 0.12"
  backend "local" {}
}

locals {
  # if variables not defined, then use var.cluster_name
  resource_group               = var.resource_group != "" ? var.resource_group : var.cluster_name
  log_analytics_workspace_name = var.log_analytics_workspace_name != "" ? var.log_analytics_workspace_name : var.cluster_name
  dns_prefix                   = var.dns_prefix != "" ? var.dns_prefix : var.cluster_name
}
