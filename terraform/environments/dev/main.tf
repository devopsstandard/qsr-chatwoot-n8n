terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }

  backend "gcs" {
    bucket = "qsr-tfstate-festive-ally-443007-r4"
    prefix = "terraform/state/dev"
  }
}

# Import existing permanent GCP KMS KeyRing and Keys into state
import {
  to = module.kms.google_kms_key_ring.keyring
  id = "projects/festive-ally-443007-r4/locations/us-central1/keyRings/qsr-keyring-dev"
}

import {
  to = module.kms.google_kms_crypto_key.cosign_key
  id = "projects/festive-ally-443007-r4/locations/us-central1/keyRings/qsr-keyring-dev/cryptoKeys/cosign-signing-key"
}

import {
  to = module.kms.google_kms_crypto_key.cmek_key
  id = "projects/festive-ally-443007-r4/locations/us-central1/keyRings/qsr-keyring-dev/cryptoKeys/qsr-cmek-key"
}

# Import undeleted active Workload Identity Pool and Provider
import {
  to = module.wif.google_iam_workload_identity_pool.github_pool
  id = "projects/festive-ally-443007-r4/locations/global/workloadIdentityPools/github-actions-pool-dev"
}

import {
  to = module.wif.google_iam_workload_identity_pool_provider.github_provider
  id = "projects/festive-ally-443007-r4/locations/global/workloadIdentityPools/github-actions-pool-dev/providers/github-actions-provider"
}

import {
  to = module.wif.google_service_account.cicd_sa
  id = "projects/festive-ally-443007-r4/serviceAccounts/qsr-cicd-sa-dev@festive-ally-443007-r4.iam.gserviceaccount.com"
}

module "vpc" {
  source      = "../../modules/vpc"
  project_id  = var.project_id
  region      = var.region
  environment = "dev"
}

module "kms" {
  source      = "../../modules/kms"
  project_id  = var.project_id
  location    = var.region
  environment = "dev"
}

module "artifact_registry" {
  source      = "../../modules/artifact-registry"
  project_id  = var.project_id
  location    = var.region
  environment = "dev"
  kms_key_id  = module.kms.cmek_key_id
}

module "wif" {
  source      = "../../modules/wif"
  project_id  = var.project_id
  environment = "dev"
  github_repo = var.github_repo
}

module "secrets" {
  source      = "../../modules/secrets"
  project_id  = var.project_id
  environment = "dev"
  kms_key_id  = module.kms.cmek_key_id
}


# Isolated Cloud SQL Instance for Chatwoot
module "cloud_sql_chatwoot" {
  source               = "../../modules/cloud-sql"
  project_id           = var.project_id
  region               = var.region
  environment          = "dev"
  instance_name_suffix = "cw-psql"
  network_id           = module.vpc.network_id
  psa_connection_id    = module.vpc.psa_connection_id
  database_name        = "chatwoot_dev"
  database_user        = "chatwoot_user"
  tier                 = "db-custom-2-7680"
  availability_type    = "ZONAL" # Zonal for dev cost-optimization
  kms_key_id           = module.kms.cmek_key_id
}

# Isolated Cloud SQL Instance for n8n
module "cloud_sql_n8n" {
  source               = "../../modules/cloud-sql"
  project_id           = var.project_id
  region               = var.region
  environment          = "dev"
  instance_name_suffix = "n8n-psql"
  network_id           = module.vpc.network_id
  psa_connection_id    = module.vpc.psa_connection_id
  database_name        = "n8n_dev"
  database_user        = "n8n_user"
  tier                 = "db-custom-2-7680"
  availability_type    = "ZONAL" # Zonal for dev cost-optimization
  kms_key_id           = module.kms.cmek_key_id
}

# Memorystore Redis for Queue Management
module "memorystore" {
  source         = "../../modules/memorystore"
  project_id     = var.project_id
  region         = var.region
  environment    = "dev"
  network_id     = module.vpc.network_id
  memory_size_gb = 2
}

# Private VPC-Native GKE Standard Cluster
module "gke" {
  source                        = "../../modules/gke"
  project_id                    = var.project_id
  region                        = var.region
  environment                   = "dev"
  network_id                    = module.vpc.network_id
  subnet_id                     = module.vpc.subnet_id
  pods_secondary_range_name     = module.vpc.pods_secondary_range_name
  services_secondary_range_name = module.vpc.services_secondary_range_name
  ondemand_machine_type         = "e2-standard-4"
  spot_machine_type             = "e2-standard-4"
}
