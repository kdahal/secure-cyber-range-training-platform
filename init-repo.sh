#!/bin/bash

# init-repo.sh: Initialize the Secure Cyber Range Training Platform GitHub repo
# Run this after cloning an empty repo: git clone <repo-url> && cd <repo-name> && chmod +x init-repo.sh && ./init-repo.sh

set -e  # Exit on any error

echo "Initializing SC RTP DevSecOps Project Repository..."

# Create directory structure
mkdir -p .github/workflows
mkdir -p terraform
mkdir -p kubernetes
mkdir -p ansible/playbooks
mkdir -p scripts
mkdir -p app/backend
mkdir -p app/frontend
mkdir -p docs
mkdir -p tests

echo "Directory structure created."

# Initialize Git if not already (in case of fresh clone)
if [ ! -d ".git" ]; then
    git init
fi

# Create README.md
cat > README.md << 'EOF'
# Secure Cyber Range Training Platform (SC RTP)

A production-grade DevSecOps deployment of a cybersecurity training platform on Azure AKS, aligned with Circadence Project Ares.

## Overview
- **App**: Containerized Node.js/Express backend with React frontend for gamified cyber training.
- **Infra**: Azure AKS, Terraform IaC, CosmosDB (MongoDB), Azure SQL.
- **Ops**: GitHub Actions CI/CD, Datadog monitoring, Ansible config, Key Vault secrets.
- **Security**: SSL/TLS, RBAC, SonarQube scans.

## Quick Start
1. Clone: `git clone https://github.com/YOUR_USERNAME/secure-cyber-range-training-platform.git`
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
EOF

# Create .gitignore (Node.js template)
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
*.log

# Terraform
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl

# Kubernetes
*.yaml.bak

# Secrets
*.env
*.pem
secrets/

# IDE
.vscode/
.idea/
EOF

# Create basic workflow file: ci-cd.yml
cat > .github/workflows/ci-cd.yml << 'EOF'
name: CI/CD Pipeline
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-test-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Build Docker
      run: docker build -t scrtp-app ./app
    - name: SonarQube Scan
      uses: sonarqube/scan-action@master
      env:
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
    - name: Test
      run: npm test  # Includes e2e

  deploy:
    needs: build-test-scan
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v3
    - name: Terraform Apply
      uses: hashicorp/terraform-github-actions/apply@v0.5.0
      with:
        tf_dir: terraform
      env:
        ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
    - name: Deploy to AKS
      uses: azure/k8s-deploy@v4
      with:
        manifests: kubernetes/
        images: yourdockerhub/scrtp-backend: ${{ github.sha }}
        namespace: training
      env:
        AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        KUBECONFIG: ${{ secrets.KUBECONFIG }}
    - name: Ansible Config
      uses: dawidd6/action-ansible-playbook@v2
      with:
        playbook: ansible/playbooks/deploy-config.yml
      env:
        ANSIBLE_HOST_KEY_CHECKING: False
EOF

# Create SonarQube scan workflow
cat > .github/workflows/sonarqube-scan.yml << 'EOF'
name: SonarQube Scan
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  sonar-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    - name: SonarQube Scan
      uses: SonarSource/sonarqube-scan-action@master
      env:
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
EOF

# Create Terraform files (basic templates)
cat > terraform/main.tf << 'EOF'
provider "azurerm" {
  features {}
}

# Add your resources here, e.g.:
# resource "azurerm_resource_group" "scrtp_rg" { ... }
EOF

cat > terraform/variables.tf << 'EOF'
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "East US"
}
EOF

cat > terraform/outputs.tf << 'EOF'
# Add outputs here, e.g.:
# output "resource_group_name" { value = azurerm_resource_group.scrtp_rg.name }
EOF

cat > terraform/backend.tf << 'EOF'
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestorage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
EOF

# Create Kubernetes manifests (placeholders)
cat > kubernetes/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: training
EOF

cat > kubernetes/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scrtp-app
  namespace: training
spec:
  replicas: 1
  selector:
    matchLabels:
      app: scrtp
  template:
    metadata:
      labels:
        app: scrtp
    spec:
      containers:
      - name: backend
        image: nginx  # Placeholder; replace with your image
        ports:
        - containerPort: 80
EOF

cat > kubernetes/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: scrtp-service
  namespace: training
spec:
  selector:
    app: scrtp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

cat > kubernetes/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: scrtp-ingress
  namespace: training
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt-prod"  # For SSL
spec:
  tls:
  - hosts:
    - scrtp.training
    secretName: scrtp-tls
  rules:
  - host: scrtp.training
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: scrtp-service
            port:
              number: 80
EOF

# Create Ansible playbook placeholder
cat > ansible/playbooks/deploy-config.yml << 'EOF'
---
- name: Deploy Config
  hosts: localhost
  tasks:
    - name: Placeholder task
      debug:
        msg: "Ansible config applied (e.g., SSL renewal, proxy setup)"
EOF

# Create scripts
cat > scripts/backup-cleanup.sh << 'EOF'
#!/bin/bash
echo "Running backup and cleanup..."
# Add backup logic here, e.g., az cosmosdb mongodb collection backup ...
echo "Backup completed."
EOF

chmod +x scripts/backup-cleanup.sh

cat > scripts/monitor-alerts.py << 'EOF'
#!/usr/bin/env python3
# Placeholder for Datadog alerts
print("Monitoring alerts via Datadog API...")
# import datadog
# api.Monitor.create(type="metric alert", query="avg:system.cpu.user{*} > 0.8")
EOF

chmod +x scripts/monitor-alerts.py

# Create app placeholders
cat > app/backend/package.json << 'EOF'
{
  "name": "scrtp-backend",
  "version": "1.0.0",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "mongoose": "^7.0.0",
    "mssql": "^9.0.0"
  }
}
EOF

cat > app/backend/server.js << 'EOF'
const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('SC RTP Backend Ready'));
app.listen(3000, () => console.log('Server on port 3000'));
EOF

cat > app/frontend/package.json << 'EOF'
{
  "name": "scrtp-frontend",
  "version": "1.0.0",
  "dependencies": {
    "react": "^18.0.0"
  },
  "scripts": {
    "start": "react-scripts start"
  }
}
EOF

# Create docs placeholder
cat > docs/outage-postmortem.md << 'EOF'
# Outage Postmortem Template

## Incident Summary
- Date: YYYY-MM-DD
- Duration: X hours
- Impact: High (e.g., app downtime)

## Timeline
- HH:MM: Event

## Root Cause
Analysis here.

## Resolution
Fixes applied.

## Action Items
- [ ] Implement monitoring for Y
EOF

# Create tests placeholder
cat > tests/e2e-tests.js << 'EOF'
// Placeholder E2E test (use Cypress or Jest)
console.log("E2E tests: App health check passes.");
EOF

# Add all files, commit
git add .
git commit -m "Initial project structure: SC RTP DevSecOps setup with dirs, templates, and placeholders"

echo "Repository initialized successfully!"
echo "Next steps:"
echo "1. Set up GitHub Secrets for CI/CD (AZURE_CLIENT_ID, etc.)."
echo "2. Customize Terraform vars and apply: cd terraform && terraform init && terraform apply"
echo "3. Build app: cd app/backend && npm install"
echo "4. Push: git push origin main"



Testing