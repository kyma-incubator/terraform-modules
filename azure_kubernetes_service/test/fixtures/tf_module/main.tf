provider "azurerm" {
  version         = "~>1.5"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

module "azure-kubernetes-service" {
  source                       = "../../.."
  client_id                    = var.client_id
  client_secret                = var.client_secret
  subscription_id              = var.subscription_id
  tenant_id                    = var.tenant_id
  dns_prefix                   = var.dns_prefix
  cluster_name                 = var.cluster_name
  resource_group               = var.resource_group
  location                     = var.location
  log_analytics_workspace_name = var.log_analytics_workspace_name
}
