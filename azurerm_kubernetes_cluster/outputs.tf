output "client_key" {
  value       = azurerm_kubernetes_cluster.k8s.kube_config.0.client_key
  description = "Base64 encoded private key used by clients to authenticate to the Kubernetes cluster"
}

output "client_certificate" {
  value       = azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate
  description = "Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster"
}

output "cluster_ca_certificate" {
  value       = azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate
  description = "Base64 encoded public CA certificate used as the root of trust for the Kubernetes cluster"
}

output "cluster_username" {
  value       = azurerm_kubernetes_cluster.k8s.kube_config.0.username
  description = "A username used to authenticate to the Kubernetes cluster"
}

output "cluster_password" {
  value       = azurerm_kubernetes_cluster.k8s.kube_config.0.password
  description = "A password or token used to authenticate to the Kubernetes cluster"
}

output "kube_config" {
  value       = azurerm_kubernetes_cluster.k8s.kube_config_raw
  description = "Raw version of the kubeconfig"
}

output "host" {
  value       = azurerm_kubernetes_cluster.k8s.kube_config.0.host
  description = "The Kubernetes cluster server host"
}

output "resource_group" {
  value       = var.resource_group
  description = "The resource group where the cluster is created"
}

output "cluster_name" {
  value       = var.cluster_name
  description = "Name of the created cluster"
}
