output "cluster_name" {
  value = module.gke.name
}

output "cluster_endpoint" {
  value     = module.gke.endpoint
  sensitive = true
}

output "region" {
  value = var.region
}

output "argocd_namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}
