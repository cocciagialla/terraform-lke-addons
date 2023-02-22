data "linode_lke_cluster" "this" {
  id = var.lke_cluster_id
}

# Set devops-node-role labels
resource "kubernetes_labels" "nodes_label" {
  provider = kubernetes
  for_each = {for node in data.linode_lke_cluster.this.pools.0.nodes:  node.id => node}
  api_version = "v1"
  kind        = "Node"
  metadata {
    name = "lke${var.lke_cluster_id}-${each.value.id}"
  }
  labels = {
    "devops-node-role" = "apps"
  }
}

# Install metrics-server helm_chart
resource "helm_release" "metrics_server" {
  namespace        = "kube-system"
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.8.2"

  values = [file("${path.module}/confs/metrics-server-values.yaml")]
}

# Install metrics-server helm_chart
resource "helm_release" "prometheus" {
  namespace        = "kube-system"
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts/"
  chart            = "prometheus"
  version          = "15.18.0"

  #  values = [file("${path.module}/prometheus-values.yaml")]

  depends_on = [
    helm_release.metrics_server
  ]
}



