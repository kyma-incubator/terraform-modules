terraform {
  required_version = ">= 0.12"
}

# Need to use Beta provider for private_cluster feature
##########################################################
provider "google" {
  version      = "~> 2.7"
  region       = var.region
  credentials  = var.credentials_file_path
  access_token = var.google_access_token
}

# Need to use Beta provider for private_cluster feature
##########################################################
provider "google-beta" {
  version      = "~> 2.7"
  region       = var.region
  credentials  = var.credentials_file_path
  access_token = var.google_access_token
}

# Get GCP metadata from local gcloud config
##########################################################
data "google_client_config" "gcloud" {}

# VPCs
##########################################################
resource "google_compute_network" "vpc" {
  count                   = var.network_name == null ? 1 : 0
  name                    = var.name
  project                 = var.project
  auto_create_subnetworks = "false"
}

# Subnets
##########################################################
resource "google_compute_subnetwork" "subnet" {
  name                     = var.name
  project                  = var.project
  network                  = local.network_link
  region                   = var.region
  description              = var.description
  ip_cidr_range            = var.k8s_ip_ranges["node_cidr"]
  private_ip_google_access = true

  # enable_flow_logs = "${var.enable_flow_logs}" # TODO
  secondary_ip_range {
    range_name    = "${var.name}-k8s-pod"
    ip_cidr_range = var.k8s_ip_ranges["pod_cidr"]
  }

  secondary_ip_range {
    range_name    = "${var.name}-k8s-svc"
    ip_cidr_range = var.k8s_ip_ranges["svc_cidr"]
  }
}

# Create a Service Account for the GKE Nodes by default
##########################################################
resource "google_service_account" "sa" {
  count        = var.service_account == null ? 1 : 0
  account_id   = var.name
  display_name = "${var.name} SA"
  project      = var.project
}

# Create a Service Account key by default
resource "google_service_account_key" "sa_key" {
  count              = var.service_account == null ? 1 : 0
  service_account_id = google_service_account.sa[0].name
}

# Add IAM Roles to the Service Account
resource "google_project_iam_member" "iam" {
  count   = var.service_account == null ? length(var.service_account_iam_roles) : 0
  member  = "serviceAccount:${google_service_account.sa[0].email}"
  project = var.project
  role    = element(var.service_account_iam_roles, count.index)
}
