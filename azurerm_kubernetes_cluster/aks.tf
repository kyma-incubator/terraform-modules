# creating dedicated resource group for kubernetes
resource "azurerm_resource_group" "k8s" {
  name     = local.resource_group
  location = var.location
}

# workspace has to be unique across azure
resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

# create a Log Analytics (formally Operational Insights) Workspace
resource "azurerm_log_analytics_workspace" "log-workspace" {
  name                = "${local.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = var.location
  resource_group_name = azurerm_resource_group.k8s.name
  sku                 = var.log_analytics_workspace_sku
}

# comnfiguring a Log Analytics (formally Operational Insights) Solution
resource "azurerm_log_analytics_solution" "log-solution" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.log-workspace.location
  resource_group_name   = azurerm_resource_group.k8s.name
  workspace_resource_id = azurerm_log_analytics_workspace.log-workspace.id
  workspace_name        = azurerm_log_analytics_workspace.log-workspace.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# creating and configuring a managed kubernetes cluster in azure (AKS)
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  dns_prefix          = local.dns_prefix
  kubernetes_version  = var.kubernetes_version

  agent_pool_profile {
    name            = "agentpool"
    count           = var.agent_count
    vm_size         = var.agent_vm_size
    os_type         = var.agent_os_type
    os_disk_size_gb = var.agent_disk_size
  }
  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }
  addon_profile {
    oms_agent {
      enabled                    = var.aks_oms_agent
      log_analytics_workspace_id = azurerm_log_analytics_workspace.log-workspace.id
    }
  }

  role_based_access_control {
    enabled = true
  }

  tags = var.tags
}
