# GKE
##########################################################
resource "google_container_cluster" "cluster" {
  provider                    = google-beta
  name                        = var.name
  project                     = var.project
  location                    = var.region
  network                     = local.network_link
  subnetwork                  = replace(google_compute_subnetwork.subnet.self_link, "https://www.googleapis.com/compute/v1/", "", )
  cluster_ipv4_cidr           = var.k8s_ip_ranges["pod_cidr"]
  description                 = var.description
  enable_binary_authorization = lookup(var.k8s_options, "binary_authorization", false)
  enable_intranode_visibility = lookup(var.k8s_options, "enable_intranode_visibility", false)
  enable_kubernetes_alpha     = lookup(var.extras, "enable_kubernetes_alpha", false)
  enable_tpu                  = lookup(var.extras, "enable_tpu", false)
  enable_legacy_abac          = var.enable_legacy_kubeconfig
  logging_service             = lookup(var.k8s_options, "logging_service", "none")
  min_master_version          = var.k8s_version
  monitoring_service          = lookup(var.k8s_options, "monitoring_service", "none")
  remove_default_node_pool    = var.remove_default_node_pool
  # workload_identity_config = # TODO

  # Can't be set if node_pool is configured
  # initial_node_count = 1
  # resource_labels = []

  addons_config {
    horizontal_pod_autoscaling {
      disabled = ! lookup(var.k8s_options, "enable_hpa", true)
    }

    http_load_balancing {
      disabled = ! lookup(var.k8s_options, "enable_http_load_balancing", true)
    }

    kubernetes_dashboard {
      disabled = ! lookup(var.k8s_options, "enable_dashboard", false)
    }

    network_policy_config {
      disabled = ! lookup(var.k8s_options, "enable_network_policy", false)
    }

    # Only create istio config if enable_istio == true
    dynamic "istio_config" {
      for_each = lookup(var.k8s_options, "enable_istio", false) ? [true] : []
      content {
        disabled = ! lookup(var.k8s_options, "enable_istio", false)
        # If cloudrun is enabled, istio auth must be "NONE"
        auth = lookup(var.k8s_options, "enable_cloudrun", false) ? "AUTH_NONE" : "AUTH_MUTUAL_TLS"
      }
    }

    # Only enable cloudrun if istio is also enabled
    dynamic "cloudrun_config" {
      for_each = lookup(var.k8s_options, "enable_cloudrun", false) && lookup(var.k8s_options, "enable_istio", false) ? [true] : []
      content {
        disabled = ! lookup(var.k8s_options, "enable_cloudrun", false)
      }
    }
  }

  # Only create block if var.gsuite_security_group is supplied
  dynamic "authenticator_groups_config" {
    for_each = var.gsuite_security_group == null ? [] : [var.gsuite_security_group]
    content {
      security_group = var.gsuite_security_group
    }
  }

  # Only create block if var.autoscaling_resource_limits is supplied
  cluster_autoscaling {
    enabled = var.autoscaling_resource_limits == [] ? false : true
    dynamic "resource_limits" {
      for_each = var.autoscaling_resource_limits
      content {
        resource_type = lookup(resource_limits.value, "resource_type", null)
        maximum       = lookup(resource_limits.value, "maximum", null)
        minimum       = lookup(resource_limits.value, "minimum", null)
      }
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.name}-k8s-pod"
    services_secondary_range_name = "${var.name}-k8s-svc"
  }

  lifecycle {
    ignore_changes = [node_pool]
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = lookup(var.extras, "maintenance_start_time", "01:00")
    }
  }

  master_auth {
    username = null # Disable basic auth
    password = null # Disable basic auth

    client_certificate_config {
      issue_client_certificate = lookup(var.extras, "issue_client_certificate", false)
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = var.networks_that_can_access_k8s_api
    content {
      dynamic "cidr_blocks" {
        for_each = lookup(master_authorized_networks_config.value, "cidr_blocks", [])
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  network_policy {
    enabled  = lookup(var.k8s_options, "enable_network_policy", false)
    provider = lookup(var.k8s_options, "enable_network_policy", false) ? "CALICO" : "PROVIDER_UNSPECIFIED"
  }

  # Node pool changes are ignored in the lifecycle block
  node_pool {
    name = "default-pool"
    node_config {
      service_account = var.service_account == null ? google_service_account.sa[0].email : var.service_account
    }
  }

  pod_security_policy_config {
    enabled = lookup(var.k8s_options, "enable_pod_security_policy", false)
  }

  private_cluster_config {
    enable_private_endpoint = var.private_masters
    enable_private_nodes    = var.private_nodes
    master_ipv4_cidr_block  = var.k8s_ip_ranges["master_cidr"]
  }

  # Not currently supported (errors with "Blocks of type "resource_usage_export_config" are not expected here.")
  # Only create block if var.bigquery_usage_destination is supplied
  # dynamic "resource_usage_export_config" {
  #   for_each = var.bigquery_usage_destination == null ? [] : [var.bigquery_usage_destination]
  #   enable_network_egress_metering = true
  #   bigquery_destination {
  #     dataset_id = var.bigquery_usage_destination
  #   }
  # }

  timeouts {
    create = var.timeouts["create"]
    update = var.timeouts["update"]
    delete = var.timeouts["delete"]
  }

  vertical_pod_autoscaling {
    enabled = lookup(var.k8s_options, "enable_vertical_pod_autoscaling", false)
  }
}


# Node pools
resource "google_container_node_pool" "pools" {
  provider           = google-beta
  cluster            = google_container_cluster.cluster.name
  count              = length(var.node_pools)
  project            = var.project
  location           = var.region
  name               = lookup(var.node_pools[count.index], "name", format("%s-%d", var.name, count.index))
  initial_node_count = lookup(var.node_pools[count.index], "initial_node_count", 1)
  max_pods_per_node  = lookup(var.node_pools[count.index], "max_pods_per_node", 110)
  # Node version rules:
  #   - If specified, use the pool's explicitly configured version
  #   - Else fall back to the global node_version variable, which defaults to empty
  version = lookup(var.node_pools[count.index], "node_version", null)

  autoscaling {
    min_node_count = lookup(var.node_pools[count.index], "min_node_count", 1)
    max_node_count = lookup(var.node_pools[count.index], "max_node_count", 3)
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
      node_count,
    ]
  }

  management {
    auto_repair  = lookup(var.node_pools[count.index], "auto_repair", true)
    auto_upgrade = lookup(var.node_pools[count.index], "auto_upgrade", true)
  }

  node_config {
    disk_size_gb    = lookup(var.node_pools[count.index], "disk_size_gb", 20)
    disk_type       = lookup(var.node_pools[count.index], "disk_type", "pd-standard")
    image_type      = lookup(var.node_pools[count.index], "image_type", "COS")
    labels          = lookup(var.node_pools[count.index], "labels", {})
    local_ssd_count = lookup(var.node_pools[count.index], "local_ssd_count", 0)
    machine_type    = lookup(var.node_pools[count.index], "machine_type", "n1-standard-2")

    # Disable legacy API endpoints.
    metadata        = lookup(var.node_pools[count.index], "node_metadata", { disable-legacy-endpoints = "true" })
    oauth_scopes    = var.oauth_scopes
    preemptible     = lookup(var.node_pools[count.index], "preemptible", false)
    service_account = var.service_account == null ? google_service_account.sa[0].email : var.service_account
    tags            = concat(list(var.name), lookup(var.node_pools[count.index], "node_tags", []))


    # TODO add option to define flexible taints map for each pool if needed.
    # taint        = "${concat(var.node_pools_taints["all"], var.node_pools_taints[lookup(var.node_pools[count.index], "name")])}"

    workload_metadata_config {
      node_metadata = lookup(var.node_pools[count.index], "metadata_concealment", "EXPOSE")
    }
  }

  timeouts {
    create = var.timeouts["create"]
    update = var.timeouts["update"]
    delete = var.timeouts["delete"]
  }
}
