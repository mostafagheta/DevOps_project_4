# --------------------------------
# VPC
# --------------------------------

resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

# --------------------------------
# Private Subnet
# --------------------------------

resource "google_compute_subnetwork" "private" {
  name          = "gke-private-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.10.0.0/16"

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.30.0.0/16"
  }
}

# --------------------------------
# Cloud Router
# --------------------------------

resource "google_compute_router" "router" {
  name    = "gke-router"
  network = google_compute_network.vpc.id
  region  = var.region
}

# --------------------------------
# Cloud NAT
# --------------------------------

resource "google_compute_router_nat" "nat" {
  name                               = "gke-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# --------------------------------
# GKE Cluster
# --------------------------------

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 33.0"

  project_id = var.project_id
  name       = var.cluster_name
  region     = var.region

  network           = google_compute_network.vpc.name
  subnetwork        = google_compute_subnetwork.private.name
  ip_range_pods     = "pods-range"
  ip_range_services = "services-range"

  enable_private_nodes    = true
  enable_private_endpoint = false

  remove_default_node_pool = true

  node_pools = [
    {
      name         = "general-pool"
      machine_type = "e2-medium"

      min_count  = 2
      max_count  = 2
      node_count = 2

      disk_size_gb = 30
      disk_type    = "pd-standard"

      image_type = "COS_CONTAINERD"

      auto_repair  = true
      auto_upgrade = true
    }
  ]
}

# --------------------------------
# ArgoCD Namespace
# --------------------------------

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [module.gke]
}

# --------------------------------
# ArgoCD Helm Installation
# --------------------------------

resource "helm_release" "argocd" {
  name      = "argocd"
  namespace = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  depends_on = [
    module.gke,
    kubernetes_namespace.argocd
  ]

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}
