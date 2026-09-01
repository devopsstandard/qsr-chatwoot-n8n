output "keyring_id" {
  value       = google_kms_key_ring.keyring.id
  description = "The ID of the KMS KeyRing"
}

output "cosign_key_id" {
  value       = google_kms_crypto_key.cosign_key.id
  description = "The ID of the Cosign KMS CryptoKey"
}

output "cmek_key_id" {
  value       = google_kms_crypto_key.cmek_key.id
  description = "The ID of the CMEK CryptoKey"
}
