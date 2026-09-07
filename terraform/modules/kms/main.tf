# Cloud KMS KeyRing
resource "google_kms_key_ring" "keyring" {
  name     = "qsr-keyring-${var.environment}"
  location = var.location
  project  = var.project_id
}

# CryptoKey for Cosign Image Signing (Asymmetric Sign PKCS1v15 2048-bit SHA256)
resource "google_kms_crypto_key" "cosign_key" {
  name     = "cosign-signing-key"
  key_ring = google_kms_key_ring.keyring.id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm        = "RSA_SIGN_PKCS1_2048_SHA256"
    protection_level = "SOFTWARE"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# CryptoKey for CMEK Storage & Secret Encryption
resource "google_kms_crypto_key" "cmek_key" {
  name            = "qsr-cmek-key"
  key_ring        = google_kms_key_ring.keyring.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s" # 90 days rotation

  lifecycle {
    prevent_destroy = false
  }
}

data "google_project" "project" {
  project_id = var.project_id
}

# Grant Artifact Registry SA permission to encrypt/decrypt with CMEK key
resource "google_kms_crypto_key_iam_member" "ar_cmek" {
  crypto_key_id = google_kms_crypto_key.cmek_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
}

# Grant Cloud SQL SA permission to encrypt/decrypt with CMEK key
resource "google_kms_crypto_key_iam_member" "cloudsql_cmek" {
  crypto_key_id = google_kms_crypto_key.cmek_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com"
}
