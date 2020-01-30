# Create an external NAT IP
resource "google_compute_address" "nat" {
  count   = var.private_nodes && var.cloud_nat && var.nat_ip_allocation == "MANUAL_ONLY" ? 1 : 0
  name    = "${var.cluster_name}-nat"
  project = var.project
  region  = var.region
}

# Create a NAT router so the nodes can reach DockerHub, etc
resource "google_compute_router" "router" {
  count       = var.private_nodes && var.cloud_nat ? 1 : 0
  name        = var.cluster_name
  network     = local.network_link
  project     = var.project
  region      = var.region
  description = var.description

  bgp {
    asn = var.nat_bgp_asn
  }
}

resource "google_compute_router_nat" "nat" {
  count                              = var.private_nodes && var.cloud_nat ? 1 : 0
  name                               = var.cluster_name
  project                            = var.project
  router                             = google_compute_router.router[0].name
  region                             = var.region
  nat_ip_allocate_option             = var.nat_ip_allocation
  nat_ips                            = var.nat_ip_allocation == "MANUAL_ONLY" ? [google_compute_address.nat[0].self_link] : null
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnet.self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]
    secondary_ip_range_names = [
      "${var.cluster_name}-k8s-pod",
      "${var.cluster_name}-k8s-svc",
    ]
  }

  dynamic "log_config" {
    # Dynamic nested block - create content if nat_log_config is not NONE
    # https://github.com/hashicorp/terraform/blob/master/website/docs/configuration/expressions.html.md#dynamic-blocks
    for_each = var.nat_log_config == "NONE" ? [] : list(var.nat_log_config)
    content {
      filter = var.nat_log_config
      enable = true
    }
  }
}

# For old version of NAT Gateway (VM)
# Route traffic to the Masters through the default gateway. This fixes things like kubectl exec and logs
##########################################################
resource "google_compute_route" "gtw_route" {
  count            = var.private_nodes && ! var.cloud_nat ? 1 : 0
  name             = var.cluster_name
  depends_on       = [google_compute_subnetwork.subnet]
  dest_range       = google_container_cluster.cluster.endpoint
  network          = local.network_link
  next_hop_gateway = "default-internet-gateway"
  priority         = 700
  project          = var.project
  tags             = concat(list(var.cluster_name), var.node_pools[*].node_tags)
}
