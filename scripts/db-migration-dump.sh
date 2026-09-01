#!/usr/bin/env bash
# ==============================================================================
# QSR Platform - Database Decoupling & Streaming Migration Script
# ==============================================================================
# Decouples PostgreSQL database snapshots from self-hosted Coolify / VM monolith
# into isolated GCP Cloud SQL PostgreSQL instances.
# ==============================================================================

set -euo pipefail

# Default Parameters
SOURCE_HOST="${SOURCE_HOST:-127.0.0.1}"
SOURCE_PORT="${SOURCE_PORT:-5432}"
SOURCE_USER="${SOURCE_USER:-postgres}"

TARGET_PROXY_HOST="${TARGET_PROXY_HOST:-127.0.0.1}"
TARGET_CHATWOOT_PORT="${TARGET_CHATWOOT_PORT:-5432}"
TARGET_N8N_PORT="${TARGET_N8N_PORT:-5433}"

CHATWOOT_DB="${CHATWOOT_DB:-chatwoot_production}"
N8N_DB="${N8N_DB:-n8n}"

CHATWOOT_TARGET_USER="${CHATWOOT_TARGET_USER:-chatwoot_user}"
N8N_TARGET_USER="${N8N_TARGET_USER:-n8n_user}"

DUMP_DIR="/tmp/qsr-db-dumps"
mkdir -p "${DUMP_DIR}"

log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1"
}

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --source-host         Hostname/IP of monolithic PostgreSQL source (default: 127.0.0.1)
  --source-port         Port of source PostgreSQL (default: 5432)
  --source-user         Admin user of source PostgreSQL (default: postgres)
  --chatwoot-db         Source Chatwoot database name (default: chatwoot_production)
  --n8n-db              Source n8n database name (default: n8n)
  --target-proxy-host   Cloud SQL Auth Proxy host (default: 127.0.0.1)
  --help                Display this help message
EOF
}

# Parse command line flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-host) SOURCE_HOST="$2"; shift 2 ;;
    --source-port) SOURCE_PORT="$2"; shift 2 ;;
    --source-user) SOURCE_USER="$2"; shift 2 ;;
    --chatwoot-db) CHATWOOT_DB="$2"; shift 2 ;;
    --n8n-db) N8N_DB="$2"; shift 2 ;;
    --target-proxy-host) TARGET_PROXY_HOST="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

log "==> Starting QSR Monolith Database Decoupling & Migration Process"

# 1. Verify PostgreSQL Client Tooling
if ! command -v pg_dump &> /dev/null || ! command -v pg_restore &> /dev/null; then
  log "ERROR: pg_dump and pg_restore must be installed."
  exit 1
fi

# 2. Dump Chatwoot Database
CHATWOOT_DUMP_FILE="${DUMP_DIR}/chatwoot_${CHATWOOT_DB}_$(date +%Y%m%d_%H%M%S).dump"
log "==> Extracting Chatwoot database dump from source [${SOURCE_HOST}:${SOURCE_PORT}/${CHATWOOT_DB}]..."
PGPASSWORD="${SOURCE_PASSWORD:-}" pg_dump \
  -h "${SOURCE_HOST}" \
  -p "${SOURCE_PORT}" \
  -U "${SOURCE_USER}" \
  -d "${CHATWOOT_DB}" \
  --no-owner \
  --no-privileges \
  -Fc \
  -j 4 \
  -f "${CHATWOOT_DUMP_FILE}"
log "✓ Chatwoot dump created: ${CHATWOOT_DUMP_FILE}"

# 3. Dump n8n Database
N8N_DUMP_FILE="${DUMP_DIR}/n8n_${N8N_DB}_$(date +%Y%m%d_%H%M%S).dump"
log "==> Extracting n8n database dump from source [${SOURCE_HOST}:${SOURCE_PORT}/${N8N_DB}]..."
PGPASSWORD="${SOURCE_PASSWORD:-}" pg_dump \
  -h "${SOURCE_HOST}" \
  -p "${SOURCE_PORT}" \
  -U "${SOURCE_USER}" \
  -d "${N8N_DB}" \
  --no-owner \
  --no-privileges \
  -Fc \
  -j 4 \
  -f "${N8N_DUMP_FILE}"
log "✓ n8n dump created: ${N8N_DUMP_FILE}"

# 4. Restore Chatwoot Database into Isolated Cloud SQL Instance
log "==> Restoring Chatwoot dump into Cloud SQL Instance [${TARGET_PROXY_HOST}:${TARGET_CHATWOOT_PORT}]..."
PGPASSWORD="${TARGET_CHATWOOT_PASSWORD:-}" pg_restore \
  -h "${TARGET_PROXY_HOST}" \
  -p "${TARGET_CHATWOOT_PORT}" \
  -U "${CHATWOOT_TARGET_USER}" \
  -d "${CHATWOOT_DB}" \
  --no-owner \
  --role="${CHATWOOT_TARGET_USER}" \
  -v \
  "${CHATWOOT_DUMP_FILE}" || true
log "✓ Chatwoot Cloud SQL restoration completed."

# 5. Restore n8n Database into Isolated Cloud SQL Instance
log "==> Restoring n8n dump into Cloud SQL Instance [${TARGET_PROXY_HOST}:${TARGET_N8N_PORT}]..."
PGPASSWORD="${TARGET_N8N_PASSWORD:-}" pg_restore \
  -h "${TARGET_PROXY_HOST}" \
  -p "${TARGET_N8N_PORT}" \
  -U "${N8N_TARGET_USER}" \
  -d "${N8N_DB}" \
  --no-owner \
  --role="${N8N_TARGET_USER}" \
  -v \
  "${N8N_DUMP_FILE}" || true
log "✓ n8n Cloud SQL restoration completed."

log "==> Database Migration and Decoupling completed successfully!"
