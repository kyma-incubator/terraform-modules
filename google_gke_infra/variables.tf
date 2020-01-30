# Required
##########################################################
variable "cluster_name" {
  description = "Name to use as a prefix to all the resources."
}

variable "region" {
  description = "The region to create the cluster in (automatically distributes masters and nodes across zones). See: https://cloud.google.com/kubernetes-engine/docs/concepts/regional-clusters"
}

# Optional
##########################################################
variable "project" {
  description = "The ID of the google project to which the resource belongs."
  default     = null
}

variable "description" {
  default = "Managed by Terraform"
}

variable "credentials_file_path" {
  description = "Either the path to or the contents of a service account key file in JSON format."
  default     = null
}

variable "google_access_token" {
  description = "A temporary OAuth 2.0 access token obtained from the Google Authorization server, i.e. the Authorization: Bearer token used to authenticate HTTP requests to GCP APIs."
  default     = null
}


variable "enable_legacy_kubeconfig" {
  description = "Whether to enable authentication using tokens/passwords/certificates. If disabled, the gcloud client needs to be used to authenticate to k8s."
  default     = false
}

variable "kubernetes_version" {
  description = "Default K8s version for the Control Plane. See: https://www.terraform.io/docs/providers/google/r/container_cluster.html#min_master_version"
  default     = "1.15"
}

variable "private_nodes" {
  description = "If true, cluster nodes will be created without a public IP addresses. It is mandatory to specify master_ipv4_cidr_block and ip_allocation_policy with this option."
  default     = true
}

variable "private_masters" {
  description = "If true, the K8s API endpoint will not be public. This is still in WIP. Do not use."
  default     = false
}

variable "gcloud_path" {
  description = "The path to your gcloud client binary."
  default     = "gcloud"
}

variable "network_name" {
  description = "The name of an already existing network, if you do not want a network to be created by this module."
  default     = null
}

variable "service_account" {
  description = "The service account to be used by the Node VMs. If not specified, a service account will be created with minimum permissions."
  default     = null
}

variable "remove_default_node_pool" {
  description = "Whether to delete the default node pool on creation. Useful if you are adding a separate node pool resource. Defaults to false."
  default     = true
}

variable "cloud_nat" {
  description = "Whether or not to enable Cloud NAT. This is to retain compatability with clusters that use the old NAT Gateway module."
  default     = true
}

variable "nat_bgp_asn" {
  description = "Local BGP Autonomous System Number (ASN). Must be an RFC6996 private ASN, either 16-bit or 32-bit. The value will be fixed for this router resource. All VPN tunnels that link to this router will have the same local ASN."
  default     = "64514"
}

variable "prevent_destroy" {
  description = "Whether to prevent terraform from destroying the GKE cluster."
  default     = false
}

variable "nat_ip_allocation" {
  description = "How external IPs should be allocated for this NAT. Valid values are AUTO_ONLY or MANUAL_ONLY. Changing this forces a new NAT to be created."
  default     = "MANUAL_ONLY"
}

variable "nat_log_config" {
  description = "Specifies the desired filtering of logs on this NAT. Valid values include: NONE, ALL, ERRORS_ONLY, TRANSLATIONS_ONLY"
  default     = "NONE"
}

variable "gsuite_security_group" {
  description = "Grant cluster access to a GSuite group. See: https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control#groups-setup-gsuite"
  default     = null
}

# # Not currently supported (errors with "Blocks of type "resource_usage_export_config" are not expected here.")
# variable "bigquery_usage_destination" {
#   description = "The ID of a BigQuery dataset to export cluster resource usage statistics to. See: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-usage-metering"
#   default     = null
# }

locals {
  network_full_link = var.network_name == null ? google_compute_network.vpc[0].self_link : format(
    "projects/%s/global/networks/%s",
    var.project,
    var.network_name,
  )
  network_link = replace(local.network_full_link, "https://www.googleapis.com/compute/v1/", "", )
}
