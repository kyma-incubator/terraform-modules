
# Terraform Modules

## Overview

The Terraform Modules are providing ready to use [modules](https://www.terraform.io/docs/configuration/modules.html) for [Terraform](https://www.terraform.io/downloads.html), containing all needed resources to provision a [Kubernetes](https://kubernetes.io) cluster on different cloud providers.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) 0.12+

## Supported providers

- [Google Cloud Platform](google_gke_infra/README.md)

## Usage

Basic usage looks like this:

```hcl
module "k8s" {
  source  = "git::https://github.com/kyma-incubator/terraform-modules//google_gke_infra?ref=v0.0.2"
  name    = "${var.cluster_name}"
  project = "${var.project}"
  region  = "${var.region}"
}

For more details see the dedicated usage example of the specific provider related module.
