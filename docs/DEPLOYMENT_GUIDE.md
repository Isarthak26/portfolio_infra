# 📚 Complete Azure GitOps CI/CD Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Phase 1: Infrastructure Setup (Terraform)](#phase-1-infrastructure-setup)
3. [Phase 2: Kubernetes Setup](#phase-2-kubernetes-setup)
4. [Phase 3: Jenkins Setup](#phase-3-jenkins-setup)
5. [Phase 4: Full Pipeline Test](#phase-4-full-pipeline-test)
6. [Phase 5: Verification](#phase-5-verification)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Software to Install
```bash
# 1. Azure CLI
# macOS
brew install azure-cli

# Ubuntu/WSL
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# 2. Terraform
# macOS
brew install terraform

# Ubuntu/WSL (or download from terraform.io)
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# 3. kubectl (Kubernetes CLI)
# macOS
brew install kubectl

# Ubuntu/WSL
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# 4. Helm (Package Manager for Kubernetes)
# macOS
brew install helm

# Ubuntu/WSL
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 5. Docker (optional, for local testing)
# macOS: Download Docker Desktop
# Ubuntu: sudo apt-get install docker.io
```

### Verify Installation
```bash
az --version
terraform --version
kubectl version --client
helm version
docker --version  # optional
```

### Azure Account Setup
```bash
# Login to Azure
az login

# Verify login
az account show

# Set default subscription (if multiple accounts)
az account set --subscription "your-subscription-id"
```

### GitHub Setup
1. Create two repositories:
   - `portfolio-app` (your React code)
   - `portfolio-infra` (Terraform + K8s manifests)

2. Generate GitHub Personal Access Token:
   - Go to Settings → Developer settings → Personal access tokens
   - Select scopes: `repo`, `workflow`, `admin:repo_hook`
   - Copy token (save securely)

---

## Phase 1: Infrastructure Setup (Terraform)

### Step 1.1: Prepare Terraform Files

```bash
# Create project structure
mkdir portfolio-deployment
cd portfolio-deployment

# Clone infrastructure repo
git clone https://github.com/YOUR_USERNAME/portfolio-infra.git
cd portfolio-infra

# Directory structure should be:
# terraform/
#   ├── main.tf
#   ├── variables.tf
#   ├── outputs.tf
#   ├── terraform.tfvars
#   └── modules/
#       ├── vnet/
#       ├── aks/
#       ├── acr/
#       ├── jenkins/
#       └── storage/
# k8s/
#   ├── namespace.yaml
#   ├── deployment.yaml
#   ├── service.yaml
#   ├── ingress.yaml
#   └── argocd-app.yaml
```

### Step 1.2: Customize terraform.tfvars

```bash
cd terraform

# Edit terraform.tfvars
# Change storage_account_name if it's already taken (must be globally unique)
# Example: storage_account_name = "sarthaktfstate20250411"

# Verify your settings
cat terraform.tfvars
```

### Step 1.3: Initialize Terraform

```bash
# Download provider plugins
terraform init

# Expected output:
# Terraform has been successfully configured!
```

### Step 1.4: Plan Infrastructure

```bash
# Preview what will be created
terraform plan

# Review output (should show ~15 resources to create)
# If error occurs, check your Azure login: az login
```

### Step 1.5: Apply Infrastructure

```bash
# Create all Azure resources
terraform apply

# When prompted, type: yes

# ⏱️ This takes ~15-20 minutes (mostly waiting for AKS cluster creation)

# Expected output:
# Apply complete! Resources: 15 added, 0 changed, 0 destroyed.
#
# Outputs:
# aks_cluster_name = "portfolio-aks"
# acr_login_server = "portfolioacr.azurecr.io"
# jenkins_public_ip = "20.x.x.x"
# jenkins_url = "http://20.x.x.x:8080"
# kubectl_config_command = "az aks get-credentials --resource-group portfolio-rg --name portfolio-aks"
```

### Step 1.6: Save Outputs

```bash
# Save important information
terraform output > ../DEPLOYMENT_INFO.txt

# Print specific outputs
terraform output jenkins_url
terraform output acr_login_server
terraform output kubectl_config_command
```

**✅ Phase 1 Complete!** Infrastructure is created. Proceed to Phase 2.

---

## Phase 2: Kubernetes Setup

### Step 2.1: Configure kubectl

```bash
# Get AKS credentials
az aks get-credentials --resource-group portfolio-rg --name portfolio-aks

# Verify connection
kubectl cluster-info
kubectl get nodes

# Expected output: 2 nodes in Ready status
```

### Step 2.2: Install ArgoCD

```bash
# Create argocd namespace
kubectl create namespace argocd

# Install ArgoCD using Helm
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argocd/argo-cd -n argocd

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=5m

# Verify
kubectl get pods -n argocd

# Expected: All pods should be Running
```

### Step 2.3: Access ArgoCD UI

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Save this password securely

# Port-forward to access UI locally
kubectl port-forward svc/argocd-server -n argocd 8443:443

# Open browser:
# https://localhost:8443
# Username: admin
# Password: (from above)

# Note: Self-signed certificate warning is expected
```

### Step 2.4: Install Nginx Ingress Controller

```bash
# Add Nginx Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install Nginx Ingress
helm install nginx-ingress ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# Wait for LoadBalancer IP
kubectl get svc -n ingress-nginx

# Note the EXTERNAL-IP (this is your Load Balancer IP)
# Example: 20.x.x.x
```

### Step 2.5: Create Portfolio Namespace

```bash
# Go to k8s directory
cd ../k8s

# Apply namespace
kubectl apply -f namespace.yaml

# Verify
kubectl get namespace portfolio
```

### Step 2.6: Update Deployment Image Reference

**IMPORTANT:** Update the ACR registry in deployment.yaml

```bash
# Edit deployment.yaml
nano deployment.yaml

# Find this line:
# image: portfolioacr.azurecr.io/portfolio:latest

# Replace 'portfolioacr' with your actual ACR name from terraform output
# Example: your-acr-name.azurecr.io/portfolio:latest

# Save and exit (Ctrl+X, Y, Enter)
```

### Step 2.7: Create ArgoCD Application

```bash
# Edit argocd-app.yaml
nano argocd-app.yaml

# Find this line:
# repoURL: https://github.com/YOUR_GITHUB_USERNAME/portfolio-infra

# Replace YOUR_GITHUB_USERNAME with your actual GitHub username

# Save and exit

# Apply ArgoCD app
kubectl apply -f argocd-app.yaml

# Verify
kubectl get application -n argocd

# Check sync status in ArgoCD UI
# Should show "Synced" status (green)
```

**✅ Phase 2 Complete!** Kubernetes is ready with ArgoCD. Proceed to Phase 3.

---

## Phase 3: Jenkins Setup

### Step 3.1: Access Jenkins

```bash
# From terraform outputs, get Jenkins URL
# Example: http://20.x.x.x:8080

# Open in browser: http://JENKINS_PUBLIC_IP:8080

# Retrieve initial admin password
terraform output jenkins_public_ip  # Get the IP

# SSH into Jenkins VM
ssh -i jenkins_key.pem azureuser@JENKINS_PUBLIC_IP

# Inside VM, get admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Copy password, logout
exit
```

### Step 3.2: Configure Jenkins

1. **Unlock Jenkins:**
   - Paste the admin password from above
   - Click "Continue"

2. **Install Suggested Plugins:**
   - Click "Install suggested plugins"
   - Wait for installation

3. **Create Admin User:**
   - Fill in username, password, email
   - Click "Save and Continue"

4. **Configure Jenkins URL:**
   - Set URL to: `http://JENKINS_PUBLIC_IP:8080`
   - Click "Save and Finish"

### Step 3.3: Install Required Plugins

Go to **Manage Jenkins → Manage Plugins → Available:**

Search and install:
- `Docker Pipeline`
- `Docker Commons`
- `GitHub Integration`
- `Pipeline: GitHub`
- `Git`

After installation, restart Jenkins: `http://JENKINS_IP:8080/restart`

### Step 3.4: Add Credentials

Go to **Manage Jenkins → Manage Credentials → Global → Add Credentials:**

#### a) GitHub Token
```
Kind: Username with password
Scope: Global
Username: your-github-username
Password: your-github-personal-access-token
ID: github-token
Description: GitHub token for portfolio
```

#### b) ACR Credentials
```
Kind: Username with password
Scope: Global
Username: acr-admin-username (from Azure Portal)
Password: acr-admin-password
ID: acr-credentials
Description: Azure Container Registry credentials
```

**To get ACR credentials:**
```bash
# From your local machine
az acr credential show --name portfolioacr --resource-group portfolio-rg

# You'll see:
# username: portfolioacr
# passwords: [{"name": "password", "value": "xxxxx"}]
```

### Step 3.5: Create Pipeline Job

1. Click **New Item**
2. **Job name:** `portfolio-pipeline`
3. **Type:** Pipeline
4. Click OK

#### Configure Pipeline:
- **Definition:** Pipeline script from SCM
- **SCM:** Git
- **Repository URL:** `https://github.com/YOUR_USERNAME/portfolio-app.git`
- **Credentials:** Select github-token
- **Branch:** `*/main`
- **Script Path:** `Jenkinsfile`
- Click **Save**

### Step 3.6: Add GitHub Webhook

1. Go to your `portfolio-app` GitHub repo
2. Click **Settings → Webhooks → Add webhook**
3. **Payload URL:** `http://JENKINS_PUBLIC_IP:8080/github-webhook/`
4. **Content type:** `application/json`
5. **Which events?** Select: "Just the push event"
6. Click **Add webhook**

**Test webhook:**
```bash
# Go to webhook settings, click "Recent Deliveries"
# You should see a successful delivery (green checkmark)
```

**✅ Phase 3 Complete!** Jenkins is configured. Proceed to Phase 4.

---

## Phase 4: Full Pipeline Test

### Step 4.1: Make a Code Change

```bash
# Clone your portfolio-app repo
git clone https://github.com/YOUR_USERNAME/portfolio-app.git
cd portfolio-app

# Make a small change (e.g., update title)
nano src/App.tsx

# Add a comment or change text
# Save file

# Commit and push
git add .
git commit -m "🎨 Update portfolio title"
git push origin main
```

### Step 4.2: Watch Pipeline Run

1. Go to Jenkins: `http://JENKINS_PUBLIC_IP:8080`
2. Click **portfolio-pipeline**
3. You should see a new build starting
4. Click the build number to watch logs
5. Pipeline stages:
   - 🔍 Checkout
   - 📦 Build Docker Image
   - 🔐 Security Scan (Trivy)
   - 🔑 Login to ACR
   - 📤 Push to ACR
   - 🔄 Update Deployment Manifest
   - ✅ Verify ArgoCD Sync

### Step 4.3: Verify ArgoCD Sync

1. Open ArgoCD UI: `https://localhost:8443` (with port-forward)
2. Click on **portfolio** application
3. You should see:
   - Status: **Synced** (green)
   - Deployment: **portfolio**
   - Service: **portfolio**
   - Ingress: **portfolio**

**✅ Phase 4 Complete!** Pipeline works end-to-end.

---

## Phase 5: Verification

### Step 5.1: Check Running Pods

```bash
# List pods in portfolio namespace
kubectl get pods -n portfolio

# Expected output:
# NAME                         READY   STATUS    RESTARTS
# portfolio-xxx-yyy            1/1     Running   0
# portfolio-zzz-www            1/1     Running   0

# Get more details
kubectl get deployment -n portfolio
kubectl get service -n portfolio
kubectl get ingress -n portfolio
```

### Step 5.2: Get LoadBalancer IP

```bash
# Get Nginx Ingress LoadBalancer IP
kubectl get svc -n ingress-nginx

# Copy the EXTERNAL-IP
# Example: 20.x.x.x
```

### Step 5.3: Access Your Website

Open browser:
```
http://LOAD_BALANCER_IP
```

Your portfolio website should load! 🎉

### Step 5.4: View Logs

```bash
# View pod logs
kubectl logs -f deployment/portfolio -n portfolio

# View specific pod
kubectl logs <pod-name> -n portfolio

# Stream logs from all pods
kubectl logs -f deployment/portfolio -n portfolio --all-containers=true
```

### Step 5.5: Test Auto-Deployment

Make another code change and push:
```bash
git add .
git commit -m "Another update"
git push origin main
```

Watch:
1. GitHub webhook triggers Jenkins
2. Jenkins builds and pushes to ACR
3. Jenkins updates `portfolio-infra` repo
4. ArgoCD detects change and syncs
5. New pods roll out automatically
6. Website updates without downtime

**✅ Full GitOps pipeline working!**

---

## Troubleshooting

### Issue: `terraform plan` fails
```bash
# Check Azure login
az account show

# Re-login if needed
az login

# Ensure you have access to subscription
az account list --output table
```

### Issue: AKS cluster creation times out
```bash
# Check cluster status
az aks show -n portfolio-aks -g portfolio-rg

# Wait a bit longer or delete and retry
terraform destroy -auto-approve
# Fix the issue
terraform apply
```

### Issue: Jenkins webhook not triggering
```bash
# Check GitHub webhook delivery
# Go to repo → Settings → Webhooks → Check "Recent Deliveries"

# Verify Jenkins URL is accessible
curl http://JENKINS_IP:8080

# Check Jenkins logs
ssh -i jenkins_key.pem azureuser@JENKINS_IP
sudo tail -f /var/log/jenkins/jenkins.log
```

### Issue: ArgoCD shows "OutOfSync"
```bash
# Force sync
kubectl patch application portfolio -n argocd \
  -p '{"metadata":{"finalizers":null}}' --type merge

# Or manually sync in UI: Click "Sync" button

# Check what's different
kubectl diff -f k8s/deployment.yaml
```

### Issue: Pods not starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n portfolio

# View events
kubectl get events -n portfolio

# Check image pull
kubectl logs <pod-name> -n portfolio
```

### Issue: Cannot access website (LoadBalancer IP)
```bash
# Verify Ingress is created
kubectl get ingress -n portfolio

# Check LoadBalancer service
kubectl get svc -n ingress-nginx

# Verify Nginx is running
kubectl get pods -n ingress-nginx

# Test connectivity
curl http://LOAD_BALANCER_IP
```

---

## Cost Optimization

### Save Money on Azure:
1. **Use Azure Free Tier credits** (included with student account)
2. **Delete resources when not using:**
   ```bash
   terraform destroy
   ```
3. **Use Standard_B2s nodes** (only $10-15/month each)
4. **Monitor costs:**
   ```bash
   az costmanagement query --timeframe TheLastMonth
   ```

---

## Next Steps

1. ✅ Add custom domain (optional)
   ```bash
   # Update ingress.yaml with your domain
   kubectl apply -f k8s/ingress.yaml
   ```

2. ✅ Add HTTPS/SSL (optional)
   ```bash
   # Install cert-manager and Let's Encrypt
   # Update ingress.yaml with certificate
   ```

3. ✅ Setup monitoring
   ```bash
   # Enable Azure Monitor for AKS
   az aks enable-addons -g portfolio-rg -n portfolio-aks -a monitoring
   ```

4. ✅ Create GitHub Actions CI/CD (alternative to Jenkins)

---

## Quick Reference Commands

```bash
# Kubernetes
kubectl get pods -n portfolio
kubectl logs deployment/portfolio -n portfolio
kubectl describe pod <pod-name> -n portfolio
kubectl port-forward svc/portfolio -n portfolio 3000:80

# Azure
az aks list -o table
az acr list -o table
az vm list -o table

# Terraform
cd terraform
terraform plan
terraform apply
terraform destroy
terraform output

# Git
git push origin main
git pull origin main
git status
git log --oneline -10

# Docker
docker build -t portfolio:latest .
docker run -p 3000:3000 portfolio:latest
docker ps
```

---

**🎉 Congratulations!** You have a fully automated Azure GitOps CI/CD pipeline!

Any issues? Check the Troubleshooting section or reach out! 🚀
