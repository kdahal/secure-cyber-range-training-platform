# Secure Cyber Range Training Platform (SC RTP)

A production-grade DevSecOps deployment of a cybersecurity training platform on Azure AKS.

## Overview
- **App**: Containerized Node.js/Express backend with React frontend for gamified cyber training.
- **Infra**: Azure AKS, Terraform IaC, CosmosDB (MongoDB), Azure SQL.
- **Ops**: GitHub Actions CI/CD, Datadog monitoring, Ansible config, Key Vault secrets.
- **Security**: SSL/TLS, RBAC, SonarQube scans.

## Quick Start
1. Clone: `git clone https://github.com/kdahal/secure-cyber-range-training-platform.git`
2. Provision: `cd terraform && terraform init && terraform apply`
3. Deploy: Push to main; CI/CD handles the rest.
4. Access: https://scrtp.training (after DNS setup)

## Repo Structure
- `.github/workflows/`: CI/CD pipelines
- `terraform/`: IaC for Azure resources
- `kubernetes/`: K8s manifests
- `ansible/`: Configuration management
- `scripts/`: Automation (backups, alerts)
- `app/`: Sample application code
- `docs/`: Postmortems and diagrams
- `tests/`: E2E tests

## Prerequisites
- Azure CLI, Terraform, kubectl, Helm
- GitHub Secrets: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, etc.

For details, see [Project Proposal](https://example.com/proposal) or run `./scripts/setup.sh`.
