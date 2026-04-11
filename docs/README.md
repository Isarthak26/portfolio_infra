# 📦 Portfolio Infrastructure Repository

Complete **Infrastructure as Code** + **Kubernetes manifests** for automated GitOps CI/CD deployment on Azure.

## 🎯 Overview

This repository contains:
- **Terraform modules** to provision Azure infrastructure (AKS, ACR, VNet, Jenkins)
- **Kubernetes manifests** for portfolio application deployment
- **ArgoCD configuration** for GitOps continuous deployment
- **Deployment guides** for complete setup

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AZURE CLOUD                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐ │
│  │    VNet      │      │     AKS      │      │     ACR      │ │
│  │              │      │   Cluster    │      │   Registry   │ │
│  │ ┌──────────┐ │      │              │      │              │ │
│  │ │ AKS      │ │      │ ┌──────────┐ │      └──────────────┘ │
│  │ │ Subnet   │─┼─────►│ │ 2x Pods  │ │                       │
│  │ └──────────┘ │      │ └──────────┘ │                       │
│  │              │      │              │                       │
│  │ ┌──────────┐ │      │ ┌──────────┐ │                       │
│  │ │ Jenkins  │ │      │ │ ArgoCD   │ │                       │
│  │ │ Subnet   │ │      │ └──────────┘ │                       │
│  │ └──────────┘ │      │              │                       │
│  │              │      │ ┌──────────┐ │                       │
│  └──────────────┘      │ │  Nginx   │ │                       │
│                        │ │ Ingress  │ │                       │
│                        │ └──────────┘ │                       │
│                        │ Load Balancer │                       │
│                        └──────────────┘                       │
│                             │                                 │
└─────────────────────────────┼─────────────────────────────────┘
                              │
                    ┌─────────▼────────┐
                    │  External Users  │
                    │  (Your Website)  │
                    └──────────────────┘
```

## 📂 Directory Structure

```
portfolio-infra/
│
├── terraform/                          # Infrastructure as Code
│   ├── main.tf                         # Main configuration
│   ├── variables.tf                    # Input variables
│   ├── outputs.tf                      # Output values
│   ├── terraform.tfvars                # Configuration values
│   ├── .gitignore                      # Protect sensitive files
│   └── modules/                        # Reusable Terraform modules
│       ├── vnet/
│       │   ├── main.tf                 # VNet + subnets
│       │   └── variables.tf
│       ├── aks/
│       │   ├── main.tf                 # AKS cluster
│       │   └── variables.tf
│       ├── acr/
│       │   ├── main.tf                 # Container registry
│       │   └── variables.tf
│       ├── jenkins/
│       │   ├── main.tf                 # Jenkins VM + setup
│       │   └── variables.tf
│       └── storage/
│           ├── main.tf                 # Terraform state storage
│           └── variables.tf
│
├── k8s/                                # Kubernetes Manifests
│   ├── namespace.yaml                  # Portfolio namespace
│   ├── deployment.yaml                 # Pod replicas + health checks
│   ├── service.yaml                    # Internal service
│   ├── ingress.yaml                    # External routing
│   └── argocd-app.yaml                 # GitOps configuration
│
└── docs/                               # Documentation
    ├── DEPLOYMENT_GUIDE.md             # Step-by-step setup
    ├── QUICK_REFERENCE.md              # Command reference
    └── ARCHITECTURE.md                 # Design decisions
```

## 🚀 Quick Start (5 Steps)

### 1. Prerequisites
```bash
# Install required tools
brew install azure-cli terraform kubectl helm
az login

# Clone this repo
git clone https://github.com/YOUR_USERNAME/portfolio-infra.git
cd portfolio-infra
```

### 2. Configure Terraform
```bash
cd terraform

# Edit terraform.tfvars (optional)
# Change storage_account_name if it exists globally

cat terraform.tfvars  # Verify settings
```

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Preview resources
terraform plan

# Create all Azure resources (15 mins)
terraform apply -auto-approve

# Save outputs
terraform output > ../DEPLOYMENT_INFO.txt
```

### 4. Setup Kubernetes
```bash
# Configure kubectl
az aks get-credentials --resource-group portfolio-rg --name portfolio-aks

# Install ArgoCD
kubectl create namespace argocd
helm install argocd argocd/argo-cd -n argocd

# Install Nginx Ingress
helm install nginx-ingress ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace

# Apply K8s manifests
cd ../k8s
kubectl apply -f .
```

### 5. Verify Deployment
```bash
# Check pods
kubectl get pods -n portfolio

# Get LoadBalancer IP
kubectl get svc -n ingress-nginx

# Access website
# Open: http://LOAD_BALANCER_IP
```

**✅ Done!** Your infrastructure is ready.

## 📋 Configuration

### terraform.tfvars
Edit `terraform/terraform.tfvars` to customize:
```hcl
location            = "centralindia"      # Azure region
aks_node_count      = 2                   # Number of nodes
aks_node_size       = "Standard_B2s"      # Node VM size
registry_name       = "portfolioacr"      # ACR name (must be unique)
storage_account_name = "portfoliotfstate" # Storage for state (must be unique)
```

### k8s/deployment.yaml
Update ACR image reference:
```yaml
image: portfolioacr.azurecr.io/portfolio:latest
# Replace 'portfolioacr' with your ACR name
```

### k8s/argocd-app.yaml
Update GitHub repo URL:
```yaml
repoURL: https://github.com/YOUR_USERNAME/portfolio-infra
# Replace YOUR_USERNAME with your GitHub username
```

## 🔄 CI/CD Pipeline

### Trigger Deployment:
1. Push code to `portfolio-app` repo
2. GitHub webhook triggers Jenkins
3. Jenkins:
   - Builds Docker image
   - Runs Trivy security scan
   - Pushes to ACR
   - Updates image tag in `portfolio-infra/k8s/deployment.yaml`
4. ArgoCD detects change
5. ArgoCD syncs K8s manifests to AKS
6. New pods deploy automatically ✅

### Manual Deployment:
```bash
# Update k8s manifests
nano k8s/deployment.yaml

# Apply changes
kubectl apply -f k8s/

# Or let ArgoCD auto-sync
# Go to ArgoCD UI: https://localhost:8443
```

## 📊 Costs

**Monthly Estimate (Azure for Students):**
- AKS Cluster (2x Standard_B2s): ~$60-80
- ACR (Basic): ~$5
- Load Balancer: ~$15
- Jenkins VM (Standard_B2s): ~$10-15
- **Total: ~$90-115/month**

**Azure for Students:** Get $100 free credits! ✨

## 🛠️ Terraform Modules

### vnet/
Virtual Network with 2 subnets:
- AKS subnet (10.0.1.0/24)
- Jenkins subnet (10.0.2.0/24)

### aks/
- Kubernetes cluster (1.29)
- 2x Standard_B2s nodes
- Auto-scaling (1-3 nodes)
- RBAC enabled
- Azure CNI networking

### acr/
- Container Registry (Basic tier)
- Admin access enabled
- Role assignment for AKS pod pull

### jenkins/
- Ubuntu 20.04 LTS VM
- Auto-installed: Docker, Jenkins, Trivy, Azure CLI
- Public IP with security group
- SSH key-based auth

### storage/
- Storage account for Terraform state
- Blob container
- Private access only

## 🔐 Security

### Kubernetes
- Non-root containers
- Resource limits
- Health checks (liveness + readiness)
- Network policies (CNI)
- Pod security policies

### Container Image
- Multi-stage Docker build (minimal size)
- Trivy security scanning
- Non-root user (UID 1001)
- Read-only root filesystem
- No privileged capabilities

### Infrastructure
- VNet isolation
- Private cluster (traffic within VNet)
- RBAC and managed identities
- Security groups on Jenkins
- Terraform state encryption

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `DEPLOYMENT_GUIDE.md` | Complete step-by-step setup |
| `QUICK_REFERENCE.md` | Command cheat sheet |
| `ARCHITECTURE.md` | Design decisions |
| `terraform/` | IaC modules |
| `k8s/` | Kubernetes manifests |

## 🧹 Cleanup

### Delete All Resources:
```bash
cd terraform
terraform destroy -auto-approve
```

This removes:
- AKS cluster
- ACR registry
- Virtual Network
- Jenkins VM
- Storage account
- All associated resources

**⚠️ WARNING:** This is irreversible!

## 🐛 Troubleshooting

### AKS cluster creation timeout
```bash
# Check cluster status
az aks show -n portfolio-aks -g portfolio-rg

# Wait a bit longer or delete and retry
terraform destroy -auto-approve
terraform apply -auto-approve
```

### Pods not starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n portfolio

# View logs
kubectl logs deployment/portfolio -n portfolio
```

### ArgoCD out of sync
```bash
# Force sync
kubectl patch application portfolio -n argocd -p '{"metadata":{"finalizers":null}}'
```

### Cannot access website
```bash
# Verify Ingress
kubectl get ingress -n portfolio

# Check LoadBalancer
kubectl get svc -n ingress-nginx

# Test connectivity
curl http://LOAD_BALANCER_IP
```

## 📖 Learn More

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Official Docs](https://kubernetes.io/docs)
- [ArgoCD Documentation](https://argoproj.github.io/argo-cd)
- [Azure Kubernetes Service Docs](https://learn.microsoft.com/en-us/azure/aks)

## 🤝 Contributing

Found an issue? Want to improve?
1. Fork the repo
2. Create a feature branch
3. Commit changes
4. Push and create a pull request

## 📄 License

MIT License - see LICENSE file

## 👤 Author

**Sarthak Bordia**
- GitHub: [@sarthakbordia](https://github.com/sarthakbordia)
- LinkedIn: [Sarthak Bordia](https://linkedin.com/in/sarthak-bordia)

---

**Happy Deploying! 🚀**

For detailed setup, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
For command reference, see [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
