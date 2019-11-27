# **AKS module**

Terraform module for creating Azure Kubernetes Service (AKS)


## Steps

* create a dedicated resource group
* create `Log Analytics Workspace`
* configure `Log Analitcs Solution`
* create a managed kubernetes cluster

## Prerequisites
* Azure needs to be configured with proper subscription, tenant and client configurations
### Variables
```hcl
variable "subscription_id" {
  type        = string
  description = "azurerem provider subscription_id"
}
variable "tenant_id" {
  type        = string
  description = "azurerem provider tenant_id"
}
variable "client_id" {
  type        = string
  description = "Kubernetes service principal client id and azurerm provider client_id"
}
variable "client_secret" {
  type        = string
  description = "Kubernetes service principal client secret and azurerem provider client_secret"
}
variable "dns_prefix" {
  type        = string
  description = "DNS prefix of the 'azurerm_kubernetes_cluster'"
}
variable "cluster_name" {
  type        = string
  description = "The name of the 'azurerm_kubernetes_cluster'"
}
variable "resource_group" {
  type        = string
  description = "The name of the resource group within the virtual network"
}
variable "location" {
  type        = string
  description = "The location of the kubernetes clutser deployment"
}
variable "log_analytics_workspace_name" {
  type        = string
  description = "The name of the Log Analytics Workspace"
}
```
## Optional variables
```hcl
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
  description = "The size of the virtual machines "
  default     = "Standard_DS3_v2"
}
variable "agent_os_type" {
  type        = string
  description = "The operating system type of the virtual machines"
  default     = "Linux"
}
variable "kubernetes_version" {
  type        = string
  description = "Version of the Kubernetes (https://aka.ms/supported-version-list)"
  default     = "1.12.8"
}
variable "agent_disk_size" {
  type        = number
  description = "The OSDiskSize for Agent agentpool cannot be less than 30GB or larger than 2048GB"
  default     = 30
}
variable "log_analytics_workspace_sku" {
  type        = string
  description = "The pricing level of the Log Analytics workspace (https://azure.microsoft.com/pricing/details/monitor)"

  default     = "PerGB2018"
}
```
## Testing
The  `./test/fixtures/tf_module` contains an example on how to invoke the module. This is also wrapped around with `kitchen` which has the following configuration defined in `.kitchen.yaml`
```yaml
---
driver:
name: terraform
root_module_directory: test/fixtures/tf_module
parallelism: 4
command_timeout: 3600
variables:
  client_id: "<%= ENV['AZURE_CLIENT_ID'] %>"
  client_secret: "<%= ENV['AZURE_CLIENT_SECRET'] %>"
  subscription_id: "<%= ENV['AZURE_SUBSCRIPTION_ID'] %>"
  tenant_id: "<%= ENV['AZURE_TENANT_ID'] %>"
  cluster_name: "kitchen-test"
  dns_prefix: "kitchen-dns"
  location: "northeurope"
  log_analytics_workspace_name: "kitchen-ws"
  resource_group: "kitchen-rg"
  
provisioner:
  name: terraform
  
verifier:
  name: terraform
  
platforms:
  - name: aks
  verifier:
    systems:
      - name: aks
        backend: azure
        profile_locations:
          - test/integration/default
        controls:
          - aks-001

suites:
  - name: aks_test
```
To perform a test with `kitchen-terraform`  the [inspec](https://www.inspec.io/) and [kitchen-terraform](https://newcontext-oss.github.io/kitchen-terraform/) tools are necessary to be installed. Also the following variables are necessary to be exported to `env` (these variables are used both by `terraform` and `inspec`)
* `AZURE_CLIENT_ID`
* `AZURE_CLIENT_SECRET`
* `AZURE_SUBSCRIPTION_ID`
* `AZURE_TENANT_ID`

Once configured a test can be executed with the `kitchen test` command which will go through the following phases:
* `kitchen create` -> `kitchen converge` -> `kitchen verify` -> `kitchen destroy`
* `terraform init` -> `terraform apply` -> `inspec exec` -> `terraform destroy`
