# Remote GCS state configuration template
# Environment specific backend configs are provided via -backend-config in CI/CD or env folders
terraform {
  backend "gcs" {}
}
