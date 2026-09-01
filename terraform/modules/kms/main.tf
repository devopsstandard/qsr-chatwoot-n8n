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
