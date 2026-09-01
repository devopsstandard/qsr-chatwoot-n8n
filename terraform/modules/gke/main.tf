# Service Account for GKE Nodes
resource "google_service_account" "gke_nodes_sa" {
  account_id   = "qsr-gke-nodes-sa-${var.environment}"
  display_name = "QSR GKE Nodes Service Account (${var.environment})"
  project      = var.project_id
}

# Grant GKE Nodes SA minimum permissions (log writer, metric writer, AR reader)
resource "google_project_iam_member" "node_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes_sa.email}"
}

resource "google_project_iam_member" "node_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes_sa.email}"
}

resource "google_project_iam_member" "node_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes_sa.email}"
}

# Private VPC-Native GKE Standard Cluster (Control Plane & Base definition)
resource "google_container_cluster" "primary" {
  name                     = "qsr-gke-cluster-${var.environment}"
  location                 = var.region
  project                  = var.project_id
  network                  = var.network_id
  subnetwork               = var.subnet_id
  remove_default_node_pool = true
  initial_node_count       = 1

  # VPC-Native IP Allocation
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Private Cluster Configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Keep control plane accessible via Master Authorized Networks
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Master Authorized Networks
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_cidrs
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Workload Identity Configuration
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Addons Configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
  }

  # Enable Secrets Store CSI Driver for Secret Manager Integration
  secret_manager_config {
    enabled = true
  }

  # Release Channel
  release_channel {
    channel = "REGULAR"
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}

# 1. On-Demand Node Pool (For Web / API / Ingress Workloads)
resource "google_container_node_pool" "ondemand_nodes" {
  name       = "qsr-ondemand-pool-${var.environment}"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = 1

  autoscaling {
    min_node_count = 2
    max_node_count = 10
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    spot         = false
    machine_type = var.ondemand_machine_type
    disk_size_gb = 50
    disk_type    = "pd-ssd"
    image_type   = "COS_CONTAINERD"

    service_account = google_service_account.gke_nodes_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      "workload-type"             = "ondemand"
      "app.kubernetes.io/env"     = var.environment
      "app.kubernetes.io/part-of" = "qsr-platform"
    }

    tags = ["qsr-gke-node", "qsr-ondemand-node"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# 2. Spot Node Pool (For Background Workers & Retryable Queue Jobs)
resource "google_container_node_pool" "spot_nodes" {
  name       = "qsr-spot-pool-${var.environment}"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 20
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    spot         = true
    machine_type = var.spot_machine_type
    disk_size_gb = 50
    disk_type    = "pd-ssd"
    image_type   = "COS_CONTAINERD"

    service_account = google_service_account.gke_nodes_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    taint {
      key    = "workload"
      value  = "spot"
      effect = "NO_SCHEDULE"
    }

    labels = {
      "workload-type"              = "spot"
      "cloud.google.com/gke-spot"  = "true"
      "app.kubernetes.io/env"      = var.environment
      "app.kubernetes.io/part-of"  = "qsr-platform"
    }

    tags = ["qsr-gke-node", "qsr-spot-node"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
