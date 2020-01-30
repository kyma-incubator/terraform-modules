output "cluster_name" {
  value = google_container_cluster.cluster.name
}

output "kubeconfig" {
  sensitive = true
  value     = var.enable_legacy_kubeconfig ? local.legacy_kubeconfig : local.gcloud_kubeconfig
}

output "endpoint" {
  value = google_container_cluster.cluster.endpoint
}

output "cluster_ca_certificate" {
  sensitive = true
  value     = google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
}

output "client_certificate" {
  sensitive = true
  value     = google_container_cluster.cluster.master_auth[0].client_certificate
}

output "client_key" {
  sensitive = true
  value     = google_container_cluster.cluster.master_auth[0].client_key
}

output "network_name" {
  value = google_compute_network.vpc.*.name
}

output "network_self_link" {
  value = google_compute_network.vpc.*.self_link
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

output "k8s_ip_ranges" {
  value = var.k8s_ip_ranges
}

output "instace_urls" {
  value = google_container_cluster.cluster.instance_group_urls
}

output "service_account" {
  value = var.service_account == null ? google_service_account.sa[0].email : var.service_account
}

output "service_account_key" {
  sensitive = true
  value     = var.service_account == null ? google_service_account_key.sa_key[0].private_key : null
}

# Render Kubeconfig output template
locals {
  # Kubeconfig using certificate
  legacy_kubeconfig = <<KUBECONFIG

apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    server: https://${google_container_cluster.cluster.endpoint}
    certificate-authority-data: ${google_container_cluster.cluster.master_auth[0].cluster_ca_certificate}
  name: gke-${var.cluster_name}
users:
- name: gke-${var.cluster_name}
  user:
    client-certificate-data: ${google_container_cluster.cluster.master_auth[0].client_certificate}
    client-key-data: ${google_container_cluster.cluster.master_auth[0].client_key}
contexts:
- context:
    cluster: gke-${var.cluster_name}
    user: gke-${var.cluster_name}
  name: gke-${var.cluster_name}
current-context: gke-${var.cluster_name}

KUBECONFIG

  # Kubeconfig using gcloud binary instead of certificate
  gcloud_kubeconfig = <<KUBECONFIG

apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    server: https://${google_container_cluster.cluster.endpoint}
    certificate-authority-data: ${google_container_cluster.cluster.master_auth[0].cluster_ca_certificate}
  name: gke-${var.cluster_name}
users:
- name: gke-${var.cluster_name}
  user:
    auth-provider:
      config:
        cmd-args: config config-helper --format=json
        cmd-path: "${var.gcloud_path}"
        expiry-key: '{.credential.token_expiry}'
        token-key: '{.credential.access_token}'
      name: gcp
contexts:
- context:
    cluster: gke-${var.cluster_name}
    user: gke-${var.cluster_name}
  name: gke-${var.cluster_name}
current-context: gke-${var.cluster_name}

KUBECONFIG
}

output "wait_for_resource_create" {
  value = null_resource.create_k8s_resources[*].id
}

output "wait_for_resource_destroy" {
  value = null_resource.destroy_k8s_resources[*].id
}
