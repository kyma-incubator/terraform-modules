# Map: K8s IP ranges
###############################
variable "k8s_ip_ranges" {
  type        = map(string)
  description = "See recommended IP range sizing: https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips#defaults_limits"

  default = {
    master_cidr = "172.16.0.0/28" # Specifies a private RFC1918 block for the master's VPC. The master range must not overlap with any subnet in your cluster's VPC. The master and your cluster use VPC peering. Must be specified in CIDR notation and must be /28 subnet. See: https://www.terraform.io/docs/providers/google/r/container_cluster.html#master_ipv4_cidr_block 10.0.82.0/28
    pod_cidr    = "10.60.0.0/14"  # The IP address range of the kubernetes pods in this cluster.
    svc_cidr    = "10.190.16.0/20"
    node_cidr   = "10.190.0.0/22"
  }
}

# Map: K8s Control Plane Options
###############################
variable "k8s_options" {
  type        = map(string)
  description = "Extra options to configure K8s. All options must be specified when passed as a map variable input to this module."

  default = {
    enable_binary_authorization     = false  # If enabled, all container images will be validated by Google Binary Authorization.
    enable_cloudrun                 = false  # Whether to enable the CloudRun addon. It requires Istio to also be enabled.
    enable_dashboard                = false  # Whether the Kubernetes Dashboard is enabled for this cluster.
    enable_hpa                      = true   # The status of the Horizontal Pod Autoscaling addon, which increases or decreases the number of replica pods a replication controller has based on the resource usage of the existing pods. It ensures that a Heapster pod is running in the cluster, which is also used by the Cloud Monitoring service.
    enable_http_load_balancing      = true   # The status of the HTTP (L7) load balancing controller addon, which makes it easy to set up HTTP load balancers for services in a cluster.
    enable_intranode_visibility     = false  # Whether Intra-node visibility is enabled for this cluster. This makes same node pod to pod traffic visible for VPC network.
    enable_istio                    = false  # Whether to enable the Istio addon
    enable_network_policy           = false  # Whether we should enable the network policy addon for the master. This must be enabled in order to enable network policy for the nodes. It can only be disabled if the nodes already do not have network policies enabled.
    enable_pod_security_policy      = false  # Whether to enable the PodSecurityPolicy controller for this cluster. If enabled, pods must be valid under a PodSecurityPolicy to be created.
    enable_vertical_pod_autoscaling = false  # Whether to enable Vertical Pod Autoscaling, which automatically adjusts the resources of pods as needed.
    logging_service                 = "none" # The logging service that the cluster should write logs to. Available options include logging.googleapis.com, logging.googleapis.com/kubernetes, and none.
    monitoring_service              = "none" # The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Google Cloud Monitoring API. VM metrics will be collected by Google Compute Engine regardless of this setting Available options include monitoring.googleapis.com, monitoring.googleapis.com/kubernetes, and none.
  }
}

variable "deploy" {
  type        = map(string)
  description = "Optional K8s resources that can be deployed on the cluster after creation."

  default = {
    network_policy      = false # Whether to install a Network Policy to block access to the GCP Metadata API and a CronJob to monitor namespaces and apply Network Policies to them.
    pod_security_policy = false # Whether to install PSPs to block running containers as root and using host network.
  }
}

# Map: Extra Options
###############################
variable "extras" {
  type        = map(string)
  description = "Extra options to configure K8s. See README.md or tf-gke.tf for more info."
  default     = {}
}

# Map: Timeouts
###############################
variable "timeouts" {
  type        = map(string)
  description = "Configurable timeout values for the various cluster operations."

  default = {
    create = "20m"  # The default timeout for a cluster create operation.
    update = "360m" # The default timeout for a cluster update operation (6 hours - node upgrades can take a long time)
    delete = "20m"  # The default timeout for a cluster delete operation.
  }
}
