# Setup cluster credentials
##########################################################
resource "null_resource" "k8s_credentials" {
  count = var.deploy["network_policy"] || var.deploy["pod_security_policy"] || length(var.k8s_resources_to_create) >= 1 ? 1 : 0 == 1 ? 1 : 0

  triggers = {
    host                   = md5(var.name)
    endpoint               = md5(google_container_cluster.cluster.endpoint)
    cluster_ca_certificate = md5(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
    netpolicy              = filemd5(format("%s/%s", path.module, "k8s_resources/networkPolicies/cronjob.yaml", ), )
    psp                    = filemd5(format("%s/%s", path.module, "k8s_resources/podsecurityPolicies/podSecurityPolicies.yaml", ), )
    new_resources          = md5(join(",", var.k8s_resources_to_create))
  }

  provisioner "local-exec" {
    command = <<EOF
set -euo pipefail
gcloud container clusters get-credentials "${var.name}" --region="${var.region}" --project="${var.project}"
set +o errexit
CRB_OUTPUT=$(kubectl create clusterrolebinding "$(gcloud config get-value account)" --clusterrole=cluster-admin --user="$(gcloud config get-value account)" 2>&1)
set -o errexit
if echo "$CRB_OUTPUT" | grep -E 'created|AlreadyExists' ; then
  exit 0 ;
else
  exit 1
fi
EOF

  }
}

# Apply network policies
##########################################################
resource "null_resource" "network_policies" {
  count      = var.deploy["network_policy"] ? 1 : 0
  depends_on = [null_resource.k8s_credentials]

  triggers = {
    host                   = md5(var.name)
    endpoint               = md5(google_container_cluster.cluster.endpoint)
    cluster_ca_certificate = md5(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
    netpolicy              = filemd5(format("%s/%s", path.module, "k8s_resources/networkPolicies/cronjob.yaml", ), )
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/k8s_resources/networkPolicies/cronjob.yaml -n kube-system"
  }
}

# Apply PodSecurityPolicies
##########################################################
resource "null_resource" "podsec_policies" {
  count      = var.deploy["pod_security_policy"] ? 1 : 0
  depends_on = [null_resource.k8s_credentials]

  triggers = {
    host                   = md5(var.name)
    endpoint               = md5(google_container_cluster.cluster.endpoint)
    cluster_ca_certificate = md5(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
    psp                    = filemd5(format("%s/%s", path.module, "k8s_resources/podsecurityPolicies/podSecurityPolicies.yaml", ), )
  }

  provisioner "local-exec" {
    command = <<EOF
set -euo pipefail
kubectl apply -f ${path.module}/k8s_resources/podsecurityPolicies/podSecurityPolicies.yaml
EOF
  }
}

# Apply arbitrary K8s resrouces
##########################################################
resource "null_resource" "create_k8s_resources" {
  count      = length(var.k8s_resources_to_create)
  depends_on = [null_resource.k8s_credentials]

  triggers = {
    host                   = md5(var.name)
    endpoint               = md5(google_container_cluster.cluster.endpoint)
    cluster_ca_certificate = md5(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
    new_resources          = md5(join(",", var.k8s_resources_to_create))
  }

  # Support both versions of base64
  provisioner "local-exec" {
    command = <<EOF
set -euo pipefail
echo "${var.k8s_resources_to_create[count.index]}" | base64 -d | kubectl apply -f - \
  || echo "${var.k8s_resources_to_create[count.index]}" | base64 -D | kubectl apply -f -
EOF
  }
}

resource "null_resource" "destroy_k8s_resources" {
  count      = length(var.k8s_resources_to_destroy)
  depends_on = [null_resource.k8s_credentials]

  triggers = {
    host                   = md5(var.name)
    endpoint               = md5(google_container_cluster.cluster.endpoint)
    cluster_ca_certificate = md5(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
    new_resources          = md5(join(",", var.k8s_resources_to_destroy))
  }

  # Support both versions of base64
  provisioner "local-exec" {
    command = <<EOF
set -euo pipefail
echo "${var.k8s_resources_to_destroy[count.index]}" | base64 -d | kubectl apply -f - \
  || echo "${var.k8s_resources_to_destroy[count.index]}" | base64 -D | kubectl apply -f -
EOF
  }
}
