# List: Custom K8s resources to create
###############################
variable "k8s_resources_to_create" {
  type        = list(string)
  default     = []
  description = "A list of k8s resources to create. The module expects the resources to be base64-encoded."
}

# List: Custom K8s resources to destroy
###############################
variable "k8s_resources_to_destroy" {
  type        = list(string)
  default     = []
  description = "A list of k8s resources to destroy. The module expects the resources to be base64-encoded."
}

# List: Networks that are authorized to access the K8s API
###############################
variable "networks_that_can_access_k8s_api" {
  # type        = list(map(list(map(string))))
  description = "A list of networks that can access the K8s API. By default allows Montreal, Munich, Gliwice offices as well as Concourse and a few VPN networks."

  default = [{
    cidr_blocks = [{
      cidr_block   = "0.0.0.0/0"
      display_name = "Whole wide world"
    }]
  }]
}

# List: Minimum GCP API privileges to allow to the nodes
###############################
variable "oauth_scopes" {
  type        = list(string)
  description = "The set of Google API scopes to be made available on all of the node VMs under the default service account. See: https://www.terraform.io/docs/providers/google/r/container_cluster.html#oauth_scopes"

  default = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/compute",
  ]
}

# List: Minimum roles to grant to the default Node Service Account
###############################
variable "service_account_iam_roles" {
  type        = list(string)
  description = "A list of roles to apply to the service account if one is not provided. See: https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#use_least_privilege_sa"

  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer",
  ]
}

# List: The resources to use for node pool autoprovisioning
# see: https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-provisioning
# For example:
# autoscaling_resource_limits = [
#   {
#     resource_type = "cpu"
#     minimum = "3"
#     maximum = "10"
#   },
#   {
#     resource_type = "memory"
#     maximum = "96"
#   },
# ]
###############################
variable "autoscaling_resource_limits" {
  description = "Enables node pool autoprovisioning based on resource usage. See above comment for usage example."
  default     = []
}

variable "node_pools" {
  description = "A map of options for creating GKE nodes. See README.md or tf-gke.tf for more info."
  default     = [{}]
}
