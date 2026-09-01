## QSR Platform Infrastructure Pull Request

### Description
<!-- Summarize the architectural changes, IaC modifications, or Kubernetes updates -->

### Type of Change
- [ ] 🏗️ Terraform Infrastructure (IaC)
- [ ] 🐳 Docker Container / Microservice Definition
- [ ] ☸️ Kubernetes Manifest / KEDA Autoscaler / Kyverno Policy
- [ ] 🔒 Security / Supply-Chain / CI/CD Workflow

### Security & Compliance Verification Checklist
- [ ] All commits are signed (`git commit -S`)
- [ ] No hardcoded secrets, IP addresses, or private keys included (verified via `gitleaks`)
- [ ] Dockerfiles conform to non-root execution and multi-stage guidelines (verified via `hadolint`)
- [ ] Terraform formatting and validation passed (`terraform fmt -check`, `terraform validate`)
- [ ] Kubernetes manifests pass `kustomize build` cleanly
