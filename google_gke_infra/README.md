# GKE Infra

This Terraform module provisions a regional `GKE cluster`, `VPC`, and `Subnet`. Optionally, it can be configured to create a service account with limited permissions for the K8s Nodes if no `service_account` value is provided (see [Use Least Privilege Service Accounts for your Nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#use_least_privilege_sa)).

- [GKE Infra](#gke-infra)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
    - [Basic Usage Example](#basic-usage-example)
    - [Creating a Private Cluster](#creating-a-private-cluster)
    - [Using the Cluster as a TF Provider](#using-the-cluster-as-a-tf-provider)
    - [Deploying Custom K8s Resources](#deploying-custom-k8s-resources)
    - [Upgrading a Cluster](#upgrading-a-cluster)
      - [Update `k8s_version`](#update-k8sversion)
      - [Update `node_version`](#update-nodeversion)
  - [Variables](#variables)
    - [Required Variables](#required-variables)
    - [Optional Variables](#optional-variables)
    - [Optional List Variables](#optional-list-variables)
      - [Node Pools Variable](#node-pools-variable)
    - [Optional Map Variables:](#optional-map-variables)
      - [`k8s_ip_ranges`](#k8sipranges)
      - [`k8s_options`](#k8soptions)
      - [`deploy`](#deploy)
      - [`extras`](#extras)
      - [`timeouts`](#timeouts)
    - [Output Variables](#output-variables)
    - [Links](#links)

## Prerequisites

1. Ensure that you have a version of `terraform` that is at least `v0.12` (run `terraform version` to validate).
2. Ensure that your `gcloud` binary is configured and authenticated:

```sh
gcloud auth login
```

Alternatively, you can download your `json keyfile` from GCP using [these steps](https://cloud.google.com/sdk/docs/authorizing#authorizing_with_a_service_account) and export the path in your environment like so:

```sh
export GOOGLE_APPLICATION_CREDENTIALS=[JSON_KEYFILE_PATH]
```

3. Set google project where you'd like to deploy the cluster

```sh
export GOOGLE_PROJECT=[PROJECT_NAME]
gcloud config set project PROJECT_ID
```

4. Setup the versioning and backend info in your `main.tf` file:

**NOTE:** these values need to be hard-coded as they cannot be interpolated as variables by Terraform.

```hcl
terraform {
  required_version = ">= 0.12"

  required_providers {
    google = ">= 2.3.0"
    google-beta = ">= 2.3.0"
  }

  backend "gcs" {
    bucket = "<BUCKET_NAME>"
    region = "<REGION>"
    prefix = "<PATH>"
  }
}
```

5. Setup your provider info:

**NOTE:** Google-Beta is required to enable certain features (such as private and regional clusters - see [documentation for more info](https://www.terraform.io/docs/providers/google/provider_versions.html)).

```hcl
provider "google" {
  credentials = "${file("${var.credentials_file}")}"
  version     = "~> 2.7"
  region = "${var.region}"
}

provider "google-beta" {
  credentials = "${file("${var.credentials_file}")}"
  version     = "~> 2.7"
  region = "${var.region}"
}
```

## Usage

### Basic Usage Example

```hcl
module "k8s" {
  source  = "git::https://github.com/kyma-incubator/terraform-modules//google_gke_infra?ref=v0.0.1"
  name    = "${var.name}"
  project = "${var.project}"
  region  = "${var.region}"
  private_nodes = true  # This will disable public IPs from the nodes
}
```

**NOTE:** All parameters are configurable. Please see [below](#variables) for information on each configuration option.

### Creating a Private Cluster

By default, this creates a [Private GKE Cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters) where the nodes do not have public IP addresses. This is achieved with the `private_nodes` variable (see [optional-variables](#optional-variables)). The module deploys a [GCP Cloud NAT resource](https://cloud.google.com/nat/docs/overview?hl=en_US&_ga=2.47256615.-1497507305.1549638187) to enable public egress connectivity.

### Using the Cluster as a TF Provider

In the same terraform file, you can use the cluster this module creates by adding the following resources to your `main.tf` file:

```hcl
# Pull Access Token from gcloud client config
# See: https://www.terraform.io/docs/providers/google/d/datasource_client_config.html
data "google_client_config" "gcloud" {}

provider "kubernetes" {
  load_config_file          = false
  host                    = "${module.k8s.endpoint}"
  token                   = "${data.google_client_config.gcloud.access_token}"   # Use the token to authenticate to K8s
  cluster_ca_certificate   = "${base64decode(module.k8s.cluster_ca_certificate)}"
}
```

This uses your local `gcloud` config to get an access token for the cluster. You can then create K8s resources (namespaces, deployments, pods, etc.) on the cluster from within the same Terraform plan.

### Deploying Custom K8s Resources

This module exposes two variables that allow you to create and destroy custom K8s resources in your GKE cluster:

- `k8s_resources_to_create`
- `k8s_resources_to_destroy`

These variables expect a list of base64 encoded manifests and will apply/destroy them respectively. You can use a setup like the following in your tf plan:

```hcl
module "k8s" {
  ...
  k8s_resources_to_create = [
    "${base64encode(file("manifest-1.yml"))}",
    "${base64encode(file("manifest-2.yml"))}"
   ]

  k8s_resources_to_destroy = [ "${base64encode(file("manifest-3.yml"))}" ]
  ...
}
```

### Upgrading a Cluster

The module exposes two variables to allow the separate upgrade of the control plane and nodes:

#### Update `k8s_version`

This value configures the version of the Control Plane. It needs to be upgraded first. Generally this operation takes ~15 minutes. Once that is done, re-run `terraform plan` to validate that no further changes are needed by Terraform. If the node pools are configured for auto upgrade, GCP will take care of automatically upgrading the nodes within the upcoming weeks to match the master version, and hence you don't need to manually adjust `node_version`.

#### Update `node_version`

Once the Control Plane has been updated, set this value to the Master version as you see it in GCP. You need to explicitly state the **full semantic version string** for the nodes (ie `1.11.5-gke.4`). If you don't provide the patch version, (ie, you only use `1.11`), this will cause a permadiff in Terraform.

Finally, run `terraform apply`, and GCP will update the nodes one at a time. This operation can take some time depending on the size of your nodepool. If you find that Terraform times out, simply wait for the operation to complete in GCP and re-run `terraform plan` and `terraform apply` to reconcile the state. You can supply a higher timeout value if needed (the default is 30 minutes - see [timeouts](#timeouts)).

## Variables

For more info, please see the [variables file](variables.tf).

### Required Variables

| Variable  | Description                                  |
| :-------- | :------------------------------------------- |
| `name`    | Name to use as a prefix to all the resources. |
| `region`  | The region that hosts the cluster. Each node will be put in a different availability zone in the region for HA. |

### Optional Variables

| Variable                   | Description                         | Default                                               |
| :------------------------- | :---------------------------------- | :---------------------------------------------------- |
| `project`                  | The ID of the google project to which the resource belongs. | Value configured in `gcloud` client. |
| `description`              | A description to apply to all resources. | `Managed by Terraform` |
| `google_credentials`       | Either the path to or the contents of a service account key file in JSON format. | `null` |
| `google_access_token`      | A temporary OAuth 2.0 access token obtained from the Google Authorization server, i.e. the Authorization: Bearer token used to authenticate HTTP requests to GCP APIs. | `null` |
| `enable_legacy_kubeconfig`  | Whether to enable authentication using tokens/passwords/certificates. | `false` |
| `k8s_version`              | Default K8s version for the Control Plane. | `1.14` |
| `private_nodes`            | Whether to create a private cluster. This will remove public IPs from your nodes and create a NAT Gateway/CloudNAT to allow internet access. | `true` |
| `private_masters`          | If true, the K8s API endpoint will not be public. This is still in WIP. Do not use. | `false` |
| `gcloud_path`              | The path to your gcloud client binary. | `gcloud` |
| `network_name`             | The name of an already existing network, if you do not want a network to be created by this module. | `null` |
| `service_account`          | The service account to be used by the Node VMs. If not specified, a service account will be created with minimum permissions. | `null` |
| `remove_default_node_pool` | Whether to delete the default node pool on creation. | `true` |
| `cloud_nat`                | Whether or not to enable Cloud NAT. This is to retain compatability with clusters that use the old NAT Gateway module. | `true` |
| `nat_bgp_asn`              | Local BGP Autonomous System Number (ASN) for the NAT router. | `64514` |
| `prevent_destroy`          | Whether to prevent terraform from destroying the GKE cluster. | `false` |
| `nat_ip_allocation`        | How external IPs should be allocated for this NAT. Valid values are AUTO_ONLY or MANUAL_ONLY. Changing this forces a new NAT to be created. | `"MANUAL_ONLY"` |
| `nat_log_config`            | Specifies the desired filtering of logs on this NAT. Valid values include: NONE, ALL, ERRORS_ONLY, TRANSLATIONS_ONLY | `"NONE"` |
| `gsuite_security_group`    | Grant cluster access to a GSuite group. | `null` |

### Optional List Variables

| Variable                           | Description                            | Default                                        |
| :--------------------------------- | :------------------------------------- | :--------------------------------------------- |
| `k8s_resources_to_create`          | A list of k8s resources to create. The module expects the resources to be base64-encoded. | `[]` |
| `k8s_resources_to_destroy`         | A list of k8s resources to destroy. The module expects the resources to be base64-encoded. | `[]` |
| `networks_that_can_access_k8s_api` | A list of networks that can access the K8s API. By default allows Montreal, Munich, Gliwice offices as well as a few VPN networks. | [`see vars file`](variables-lists.tf) |
| `oauth_scopes`                     | The set of Google API scopes to be made available on all of the node VMs under the default service account. | [`see vars file`](variables-lists.tf) |
| `service_account_iam_roles`        | A list of roles to apply to the service account if one is not provided. | [`see vars file`](variables-lists.tf) |
| `autoscaling_resource_limits`      | Enables node pool autoprovisioning based on resource usage. Requires a list of resources and their min/max values. | [`see vars file`](variables-lists.tf) |

#### Node Pools Variable

The `node_pools` optional list variable specifies the node pools along with their configurations to be provisioned for the GKE cluster.

By default (if `node_pools` variable is not set by the user), a single node pool is provisioned with the same name as the cluster and the default configuration options listed below.

The configuration maps inside the `node_pools` list need to be defined in the following format:

| Variable               | Description                                                               | Default                |
| :--------------------- | :------------------------------------------------------------------------ | :--------------------- |
| `auto_repair`          | Whether the nodes will be automatically repaired.                         | `true`                 |
| `auto_upgrade`         | Whether the nodes will be automatically upgraded.                         | `true`                 |
| `disk_size_gb`         | Size of the disk attached to each node, specified in GB.                   | `20`                   |
| `disk_type`            | Type of the disk attached to each node.                                   | `"pd-standard"`        |
| `image_type`           | The image type to use for each node.                                      | `"COS"`                |
| `initial_node_count`   | The initial node count for the pool. Changing this will force recreation of the resource. | `1`    |
| `max_pods_per_node`    | The maximum number of pods per node in this node pool.                    | `110`                  |
| `labels`               | Kubernetes labels (key/value pairs) to be applied to each node.           | `{}`                   |
| `local_ssd_count`      | The amount of local SSD disks that will be attached to each cluster node. | `0`                    |
| `machine_type`         | The machine type (RAM, CPU, etc) to use for each node.                    | `"n1-standard-1"`      |
| `max_node_count`       | Maximum number of nodes to create in each zone.                           | `3`                    |
| `metadata_concealment` | How to expose the node metadata to the workload running on the node. By default this is set to EXPOSE as the network policies block access to the metadata API by IP. | `EXPOSE`  |
| `min_node_count`       | Minimum number of nodes to create in each zone.                           | `1`                    |
| `name`                 | The name of to node pool. If unset, defaults to the cluster name.         | `null`                 |
| `node_metadata`        | Metadata key/value pairs assigned to nodes in the cluster.                | [`see vars file`](variables.tf) |
| `node_tags`            | The list of instance tags applied to all nodes. If none are provided, the cluster name is used by default. | `[]` |
| `node_version`         | Default K8s versions for the Nodes.                                       | `null`                 |
| `preemptible`          | Whether to create cheaper nodes that last a maximum of 24 hours.          | `false`                |

### Optional Map Variables:

For maps (except `k8s_options`), **ALL** values in each category (`k8s_ip_ranges`, `k8s_options`, `deploy`, ...) need to be defined in the following format:

```hcl
k8s_ip_ranges = {
  master_cidr = "172.16.0.0/28"
  pod_cidr    = "10.60.0.0/14"
  svc_cidr    = "10.190.16.0/20"
  node_cidr   = "10.190.0.0/22"
}
```

#### `k8s_ip_ranges`

A map of the various IP ranges to use for K8s resources.

| Variable      | Description                           | Default                                     |
| :------------ | :------------------------------------ | :------------------------------------------ |
| `master_cidr` | Specifies a private RFC1918 block for the master's VPC.           | `172.16.0.0/28`  |
| `pod_cidr`    | The IP address range of the kubernetes pods in this cluster.     | `10.60.0.0/14`   |
| `svc_cidr`    | The IP address range of the kubernetes services in this cluster. | `10.190.16.0/20` |
| `node_cidr`   | The IP address range of the kubernetes nodes in this cluster.    | `10.190.0.0/22`  |

#### `k8s_options`

Options to configure K8s. These include enabling the dashboard, network policies, monitoring and logging, etc.

| Variable                          | Description                           | Default                                           |
| :-------------------------------- | :------------------------------------ | :------------------------------------------------ |
| `enable_binary_authorization`     | If enabled, all container images will be validated by Google Binary Authorization. | `false` |
| `enable_cloudrun`                 | Whether to enable the CloudRun addon. It requires Istio to also be enabled. Will force cluster recreation if turned on for an existing cluster. | `false` |
| `enable_dashboard`                | Whether to enable the k8s dashboard. | `false` |
| `enable_hpa`                      | Whether to enable the Horizontal Pod Autoscaling addon. | `true` |
| `enable_http_load_balancing`      | Whether to enable the HTTP (L7) load balancing controller addon. | `true` |
| `enable_intranode_visibility`     | Whether Intra-node visibility is enabled for this cluster. This makes same node pod to pod traffic visible for VPC network. | `false` |
| `enable_istio`                    | Whether to enable Istio on the cluster. | `false` |
| `enable_network_policy`           | Whether to enable the network policy addon. If enabled, this will also install PSPs and a CronJob to the cluster. | `false` |
| `enable_pod_security_policy`      | Whether to enable the PodSecurityPolicy controller for this cluster. | `false` |
| `enable_vertical_pod_autoscaling` | Whether to enable Vertical Pod Autoscaling, which automatically adjusts the resources of pods as needed. | `false` |
| `logging_service`                 | The logging service that the cluster should write logs to. | `"none"` |
| `monitoring_service`              | The monitoring service that the cluster should write metrics to. | `"none"` |

#### `deploy`

Optional K8s resources that can be deployed on the cluster after creation.

| Variable              | Description                           | Default                                               |
| :-------------------- | :------------------------------------ | :---------------------------------------------------- |
| `network_policy`      | Whether to install a Network Policy to block access to the GCP Metadata API.        | `false` |
| `pod_security_policy` | Whether to install PSPs to block running containers as root and using host network. | `false` |

#### `extras`

Extra options to configure K8s. These are options that are unlikely to change from deployment to deployment.

| Variable                  | Description                           | Default                                |
| :------------------------ | :------------------------------------ | :------------------------------------- |
| `enable_kubernetes_alpha` | Enable Kubernetes Alpha features for this cluster.                   | `false` |
| `maintenance_start_time`  | Time window specified for daily maintenance operations.               | `01:00` |
| `issue_client_certificate` | Whether client certificate authorization is enabled for this cluster  | `false` |
| `enable_tpu`              | Whether to enable Cloud TPU resources in this cluster.               | `false` |

#### `timeouts`

Configurable timeout values for the various cluster operations.

| Variable  | Description                                         | Default  |
| :-------- | :-------------------------------------------------- | :------- |
| `create`  | The default timeout for a cluster create operation. | `20m` |
| `update`  | The default timeout for a cluster update operation. | `360m` |
| `delete`  | The default timeout for a cluster delete operation. | `20m` |

### Output Variables

| Variable                   | Description                       |
| :------------------------- | :-------------------------------- |
| `cluster_name`             | The name of the cluster created by this module |
| `kubeconfig`                | A generated kubeconfig to authenticate with K8s. |
| `endpoint`                 | The API server's endpoint. |
| `cluster_ca_certificate`    | The CA certificate used to create the cluster. |
| `client_certificate`        | The client certificate to use for accessing the API (only valid if `enable_legacy_kubeconfig` is set to `true`). |
| `client_key`               | The client key to use for accessing the API (only valid if `enable_legacy_kubeconfig` is set to `true`). |
| `network_name`             | The name of the network created by this module. Useful for passing to other resources you want to create on the same VPC. |
| `network_self_link`        | The self_link of the network created by this module. Useful for passing to other resources you want to create on the same VPC. |
| `subnet_name`              | The name of the subnet created by this module. Useful for passing to other resources you want to create on the same subnet. |
| `k8s_ip_ranges`            | The ranges defined in the GKE cluster |
| `instace_urls`             | The unique URLs of the K8s Nodes in GCP. |
| `service_account`          | The email of the service account created by or supplied to this module. |
| `service_account_key`      | The key for the service account created by this module. |
| `wait_for_resource_create` | A dummy output to use to ensure that all the `k8s_resources_to_create` have finished deploying. |
| `wait_for_resource_create` | A dummy output to use to ensure that all the `k8s_resources_to_destroy` have finished destroying. |

### Links

- https://www.terraform.io/docs/providers/google/r/container_cluster.html
- https://www.terraform.io/docs/providers/google/r/compute_network.html
- https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
- https://www.terraform.io/docs/providers/google/d/datasource_google_service_account.html
- https://www.terraform.io/docs/providers/google/r/compute_route.html
- https://www.terraform.io/docs/provisioners/null_resource.html
