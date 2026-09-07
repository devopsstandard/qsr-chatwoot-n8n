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
    prefix = "terraform/state/prod"
  }
}

# Import existing permanent GCP KMS KeyRing and Keys into state
import {
  to = module.kms.google_kms_key_ring.keyring
  id = "projects/festive-ally-443007-r4/locations/us-central1/keyRings/qsr-keyring-prod"
}

import {
  to = module.kms.google_kms_crypto_key.cosign_key
  id = "projects/festive-ally-443007-r4/locations/us-central1/keyRings/qsr-keyring-prod/cryptoKeys/cosign-signing-key"
}

import {
  to = module.kms.google_kms_crypto_key.cmek_key
  id = "projects/festive-ally-443007-r4/locations/us-central1/keyRings/qsr-keyring-prod/cryptoKeys/qsr-cmek-key"
}

# Import existing Artifact Registry repository
import {
  to = module.artifact_registry.google_artifact_registry_repository.repo
  id = "projects/festive-ally-443007-r4/locations/us-central1/repositories/qsr-containers-prod"
}

module "vpc" {
  source      = "../../modules/vpc"
  project_id  = var.project_id
  region      = var.region
  environment = "prod"
}

module "kms" {
  source      = "../../modules/kms"
  project_id  = var.project_id
  location    = var.region
  environment = "prod"
}

module "artifact_registry" {
  source      = "../../modules/artifact-registry"
  project_id  = var.project_id
  location    = var.region
  environment = "prod"
  kms_key_id  = module.kms.cmek_key_id
}

module "wif" {
  source      = "../../modules/wif"
  project_id  = var.project_id
  environment = "prod"
  github_repo = var.github_repo
}

module "secrets" {
  source      = "../../modules/secrets"
  project_id  = var.project_id
  environment = "prod"
  kms_key_id  = module.kms.cmek_key_id
}


# Production Isolated Cloud SQL Instance for Chatwoot
module "cloud_sql_chatwoot" {
  source               = "../../modules/cloud-sql"
  project_id           = var.project_id
  region               = var.region
  environment          = "prod"
  instance_name_suffix = "chatwoot-db"
  network_id           = module.vpc.network_id
  psa_connection_id    = module.vpc.psa_connection_id
  database_name        = "chatwoot_production"
  database_user        = "chatwoot_user"
  tier                 = "db-custom-2-7680"
  availability_type    = "ZONAL"
  kms_key_id           = module.kms.cmek_key_id
}

# Production Isolated Cloud SQL Instance for n8n
module "cloud_sql_n8n" {
  source               = "../../modules/cloud-sql"
  project_id           = var.project_id
  region               = var.region
  environment          = "prod"
  instance_name_suffix = "n8n-db"
  network_id           = module.vpc.network_id
  psa_connection_id    = module.vpc.psa_connection_id
  database_name        = "n8n_production"
  database_user        = "n8n_user"
  tier                 = "db-custom-2-7680"
  availability_type    = "ZONAL"
  kms_key_id           = module.kms.cmek_key_id
}

# Production Memorystore Redis
module "memorystore" {
  source         = "../../modules/memorystore"
  project_id     = var.project_id
  region         = var.region
  environment    = "prod"
  network_id     = module.vpc.network_id
  memory_size_gb = 2
}

# Production Private VPC-Native GKE Standard Cluster
module "gke" {
  source                        = "../../modules/gke"
  project_id                    = var.project_id
  region                        = var.region
  environment                   = "prod"
  network_id                    = module.vpc.network_id
  subnet_id                     = module.vpc.subnet_id
  pods_secondary_range_name     = module.vpc.pods_secondary_range_name
  services_secondary_range_name = module.vpc.services_secondary_range_name
  ondemand_machine_type         = "e2-standard-4"
  spot_machine_type             = "e2-standard-4"
}
