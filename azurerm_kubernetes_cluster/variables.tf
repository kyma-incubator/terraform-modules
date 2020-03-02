### mandatory vars ###
variable "subscription_id" {
  type        = string
  description = "azurerm provider subscription_id"
}
variable "tenant_id" {
  type        = string
  description = "azurerm provider tenant_id"
}
variable "client_id" {
  type        = string
  description = "Kubernetes service principal client id and azurerm provider client_id"
}
variable "client_secret" {
  type        = string
  description = "Kubernetes service principal client secret and azurerm provider client_secret"
}
variable "cluster_name" {
  type        = string
  description = "The name of the 'azurerm_kubernetes_cluster'"
}
variable "location" {
  type        = string
  description = "The location of the kubernetes cluster deployment"
}

### optional vars (defaulting to var.cluster_name) ###
variable "resource_group" {
  type        = string
  description = "The name of the resource group within the virtual network"
  default     = ""
}
variable "log_analytics_workspace_name" {
  type        = string
  description = "The name of the Log Analytics Workspace"
  default     = ""
}
variable "dns_prefix" {
  type        = string
  description = "DNS prefix of the 'azurerm_kubernetes_cluster'"
  default     = ""
}

### optional vars  ###
variable "tags" {
  type        = map(string)
  description = "Tags to assign to the 'azurerm_kubernetes_cluster'"
  default     = {}
}
variable "agent_count" {
  type        = number
  description = "The number of agents in the agent pool"
  default     = 3
}
variable "agent_vm_size" {
  type        = string
  description = "The size of the virtual machines"
  default     = "Standard_DS3_v2"
}
variable "agent_os_type" {
  type        = string
  description = "The operating system type of the virtual machines"
  default     = "Linux"
}
variable "kubernetes_version" {
  type        = string  
  description = "Version of Kubernetes (https://aka.ms/supported-version-list)"
  default     = "1.12.8"
}
variable "agent_disk_size" {
  type        = number  
  description = "The OSDiskSize for Agent (agentpool cannot be less than 30GB or larger than 2048GB)"
  default     = 30
}
variable "log_analytics_workspace_sku" {
  type        = string
  description = "The pricing level of the Log Analytics workspace (https://azure.microsoft.com/pricing/details/monitor)"
  default     = "PerGB2018"
}
variable "aks_oms_agent" {
  type        = bool
  description = "Enable Log Analytics agent to monitor containers"
  default     = false
}
