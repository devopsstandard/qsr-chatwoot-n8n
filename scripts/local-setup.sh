#!/usr/bin/env bash
# ==============================================================================
# QSR Platform - Local Environment Tooling Verification Script
# ==============================================================================

set -euo pipefail

log_info() { echo -e "\033[0;32m[OK]\033[0m $1"; }
log_warn() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
log_err()  { echo -e "\033[0;31m[FAIL]\033[0m $1"; }

REQUIRED_TOOLS=("gcloud" "kubectl" "terraform" "docker" "cosign" "gitleaks" "hadolint" "kustomize")
MISSING_TOOLS=()

echo "==> Verifying local engineering dependencies for QSR Platform..."

for tool in "${REQUIRED_TOOLS[@]}"; do
  if command -v "$tool" &> /dev/null; then
    VERSION=$("$tool" version 2>&1 | head -n 1 || "$tool" --version 2>&1 | head -n 1)
    log_info "$tool is installed ($VERSION)"
  else
    log_err "$tool is missing"
    MISSING_TOOLS+=("$tool")
  fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
  echo ""
  log_warn "Some required tools are missing: ${MISSING_TOOLS[*]}"
  log_warn "Please install missing CLI utilities before running Terraform or container builds."
  exit 1
else
  echo ""
  log_info "All engineering tools are present and validated!"
fi
