# QSR Platform Infrastructure (`qsr-platform-infra`)

Production-grade infrastructure configuration for migrating and decoupling self-hosted **Chatwoot** (customer communications) and **n8n** (automation engine) from Coolify/monolithic VM snapshots onto **Google Cloud Platform (GCP)** using **Private VPC-Native GKE Standard**, **KEDA event-driven autoscaling**, **Isolated Cloud SQL PostgreSQL Instances**, **Memorystore Redis**, and **SLSA Level 3 supply-chain security**.

---

## 🏛️ Platform Architecture Overview

```
                                  [ DNS: devopsstandard.name.ng ]
                                                │
                                    ┌───────────┴───────────┐
                                    ▼                       ▼
                         chatwoot.devopsstandard.name.ng  n8n.devopsstandard.name.ng
                                    │                       │
                                    └───────────┬───────────┘
                                                │
                                                ▼
                                   [ Cloud Armor WAF / HTTPS Load Balancer ]
                                                │
                                                ▼
                                    ┌───────────────────────┐
                                    │  Private VPC Subnet   │
                                    └───────────┬───────────┘
                                                │
                     ┌──────────────────────────┴──────────────────────────┐
                     ▼                                                     ▼
        ┌─────────────────────────┐                           ┌─────────────────────────┐
        │  GKE On-Demand Nodes    │                           │    GKE Spot Nodes       │
        ├─────────────────────────┤                           ├─────────────────────────┤
        │ - Chatwoot Web (Rails)  │                           │ - Chatwoot Worker       │
        │ - n8n Main / Webhooks   │                           │   (Sidekiq + KEDA)      │
        │ - Cloud SQL Proxy       │                           │ - n8n Queue Worker      │
        │   Sidecars              │                           │   (BullMQ + KEDA)       │
        └────────────┬────────────┘                           └────────────┬────────────┘
                     │                                                     │
                     └──────────────────────────┬──────────────────────────┘
                                                │ (Private Service Access / Peering)
                                                ▼
         ┌─────────────────────────┬─────────────────────────┬─────────────────────────┐
         │ Cloud SQL (Chatwoot DB) │   Cloud SQL (n8n DB)    │   Memorystore Redis     │
         │ PostgreSQL 15 (HA)      │   PostgreSQL 15 (HA)    │   Standard HA           │
         └─────────────────────────┴─────────────────────────┴─────────────────────────┘
```

---

## 📁 Repository Directory Structure

```text
qsr-platform-infra/
├── .github/
│   ├── workflows/
│   │   ├── pr-checks.yaml          # Static analysis: Gitleaks, Hadolint, Terraform fmt/validate
│   │   ├── build-and-sign.yaml     # Docker buildx, Trivy scan, Cosign KMS sign, Artifact Registry push
│   │   └── cd-deploy.yaml          # GitOps trigger & Kustomize deployment rollout
│   ├── CODEOWNERS                  # Security & Infra codeowners
│   └── pull_request_template.md    # PR checklist enforcing signed commits & checks
│
├── docker/
│   ├── chatwoot/ (Dockerfile, entrypoint.sh)
│   └── n8n/ (Dockerfile, custom-nodes/)
│
├── terraform/
│   ├── backend.tf                  # GCS Remote State configuration
│   ├── versions.tf                 # Terraform >= 1.5.0 provider constraints
│   ├── environments/ (dev/, prod/)
│   └── modules/
│       ├── vpc/                    # Private VPC, Subnets, PSA Peering, Cloud NAT
│       ├── gke/                    # Private VPC-Native GKE Standard (On-Demand & Spot node pools)
│       ├── cloud-sql/              # Reusable Cloud SQL Postgres module (Private IP, HA, Backups)
│       ├── memorystore/            # Memorystore for Redis
│       ├── artifact-registry/      # Docker Artifact Registry repo with CMEK
│       ├── kms/                    # Cloud KMS KeyRing & CryptoKeys for Cosign signing
│       └── wif/                    # Workload Identity Federation for keyless GitHub Actions OIDC
│
├── k8s/
│   ├── base/
│   │   ├── chatwoot/ (Web/Worker Deployments, Service, KEDA ScaledObject)
│   │   ├── n8n/ (Main/Worker Deployments, Service, KEDA ScaledObject)
│   │   ├── common/ (SecretProviderClass, CloudSQL ServiceAccounts)
│   │   └── policies/ (Kyverno Cosign KMS verification policy)
│   └── overlays/ (dev/, prod/ with devopsstandard.name.ng Ingress)
│
├── scripts/
│   ├── local-setup.sh              # CLI tool verification
│   └── db-migration-dump.sh        # PostgreSQL snapshot decoupling script
├── .gitleaks.toml
├── .hadolint.yaml
├── .gitignore
└── README.md
```

---

## 🚀 Quickstart & Operational Runbooks

### 1. Local Tooling Validation
Before working on the codebase, verify that your local environment has the required CLI tools:
```bash
./scripts/local-setup.sh
```

### 2. Provisioning Infrastructure via Terraform
Navigate to the target environment directory (`dev` or `prod`):
```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Update project_id and github_repo in terraform.tfvars

terraform init
terraform plan
terraform apply
```

### 3. Decoupling & Migrating Snapshot Databases
Run the migration script to dump the monolithic database and restore into Cloud SQL:
```bash
./scripts/db-migration-dump.sh \
  --source-host="SOURCE_VM_IP" \
  --chatwoot-db="chatwoot_production" \
  --n8n-db="n8n" \
  --target-proxy-host="127.0.0.1"
```

### 4. Deploying Kubernetes Manifests via Kustomize
```bash
# Verify generated manifests
kustomize build k8s/overlays/prod

# Apply GitOps deployment to GKE
kubectl apply -k k8s/overlays/prod
```

---

## 🔒 Security & Compliance Safeguards

- **SLSA Level 3 Supply-Chain Security:** Container images are scanned by Trivy for CVEs and signed with **Sigstore Cosign using GCP Cloud KMS**.
- **Runtime Signature Verification:** GKE enforces image signature verification via **Kyverno admission control policies**.
- **Keyless CI/CD:** GitHub Actions authenticates to GCP via **Workload Identity Federation (WIF)** without long-lived SA keys.
- **Zero-Trust Network:** GKE nodes, Cloud SQL, and Memorystore communicate over private IPs with **Private Service Access (PSA)** and Cloud SQL Auth Proxy sidecars.
