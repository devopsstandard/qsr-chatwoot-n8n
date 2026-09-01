# Custom VPC Network
resource "google_compute_network" "vpc" {
  name                    = "qsr-vpc-${var.environment}"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnet for GKE Nodes with Secondary Ranges for VPC-Native Pods and Services
resource "google_compute_subnetwork" "subnet" {
  name                     = "qsr-gke-subnet-${var.environment}"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  project                  = var.project_id

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = var.services_cidr
  }
}

# Reserved IP Allocation for Private Service Access (Cloud SQL & Memorystore)
resource "google_compute_global_address" "psa_ip_range" {
  name          = "qsr-psa-range-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  address       = split("/", var.psa_peering_cidr)[0]
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

# Private Service Networking Connection (PSA Peering)
resource "google_service_networking_connection" "psa_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_ip_range.name]
}

# Cloud Router for Outbound NAT
resource "google_compute_router" "router" {
  name    = "qsr-router-${var.environment}"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}

# Cloud NAT for Private GKE Nodes internet access (e.g. pulling external APIs/images securely)
resource "google_compute_router_nat" "nat" {
  name                               = "qsr-nat-${var.environment}"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
