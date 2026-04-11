# 🚀 Quick Reference Card

## 1️⃣ One-Liner Setup Commands

```bash
# Login to Azure
az login && az account show

# Initialize Terraform
cd terraform && terraform init

# Plan infrastructure
terraform plan

# Deploy infrastructure (15 mins)
terraform apply -auto-approve

# Get kubectl credentials
az aks get-credentials --resource-group portfolio-rg --name portfolio-aks

# Install ArgoCD
kubectl create namespace argocd && helm install argocd argocd/argo-cd -n argocd

# Install Nginx Ingress
helm install nginx-ingress ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace

# Apply K8s manifests
kubectl apply -f k8s/namespace.yaml k8s/deployment.yaml k8s/service.yaml k8s/ingress.yaml k8s/argocd-app.yaml

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Get Jenkins URL
terraform output jenkins_url

# Get LoadBalancer IP
kubectl get svc -n ingress-nginx
```

---

## 2️⃣ Check Status Commands

```bash
# ✅ Verify Azure resources
az account show
az group list --output table
az aks list -o table
az acr list -o table

# ✅ Check Kubernetes cluster
kubectl cluster-info
kubectl get nodes
kubectl get all -A

# ✅ Check pods
kubectl get pods -n portfolio
kubectl get pods -n argocd
kubectl get pods -n ingress-nginx

# ✅ Check services
kubectl get svc -n portfolio
kubectl get svc -n ingress-nginx

# ✅ Check ingress
kubectl get ingress -n portfolio

# ✅ Check ArgoCD app
kubectl get application -n argocd
kubectl describe application portfolio -n argocd

# ✅ Check deployment status
kubectl rollout status deployment/portfolio -n portfolio

# ✅ View pod logs
kubectl logs deployment/portfolio -n portfolio
kubectl logs <pod-name> -n portfolio

# ✅ Describe pod (for troubleshooting)
kubectl describe pod <pod-name> -n portfolio

# ✅ Check events
kubectl get events -n portfolio
```

---

## 3️⃣ Update/Redeploy Commands

```bash
# Push code to trigger pipeline
git add . && git commit -m "Update" && git push origin main

# Manual trigger Jenkins build
# Go to: http://JENKINS_IP:8080/job/portfolio-pipeline/

# Force ArgoCD sync
kubectl patch application portfolio -n argocd -p '{"metadata":{"finalizers":null}}'

# Rollout new deployment
kubectl rollout restart deployment/portfolio -n portfolio

# Check rollout history
kubectl rollout history deployment/portfolio -n portfolio

# Rollback to previous version
kubectl rollout undo deployment/portfolio -n portfolio
```

---

## 4️⃣ Access Services Commands

```bash
# ArgoCD UI (port-forward)
kubectl port-forward svc/argocd-server -n argocd 8443:443
# Access: https://localhost:8443

# Jenkins UI
# Access: http://JENKINS_PUBLIC_IP:8080

# Portfolio website
# Access: http://LOAD_BALANCER_IP

# Get all important IPs
echo "Jenkins: $(terraform output jenkins_url)"
echo "LoadBalancer: $(kubectl get svc -n ingress-nginx | grep LoadBalancer | awk '{print $4}')"
echo "ACR: $(terraform output acr_login_server)"
```

---

## 5️⃣ Terraform Commands

```bash
# Initialize
cd terraform && terraform init

# Plan (preview changes)
terraform plan

# Apply (create resources)
terraform apply

# Apply without prompting
terraform apply -auto-approve

# Destroy all resources
terraform destroy

# Destroy without prompting
terraform destroy -auto-approve

# View outputs
terraform output
terraform output jenkins_url

# Refresh state
terraform refresh

# Format code
terraform fmt -recursive
```

---

## 6️⃣ Debug Commands

```bash
# Get detailed pod info
kubectl describe pod <pod-name> -n portfolio

# Get pod YAML
kubectl get pod <pod-name> -n portfolio -o yaml

# Execute command in pod
kubectl exec -it <pod-name> -n portfolio -- /bin/sh

# Stream logs
kubectl logs -f deployment/portfolio -n portfolio

# Watch pod status
kubectl get pods -n portfolio --watch

# Get all resources in namespace
kubectl get all -n portfolio

# Describe deployment
kubectl describe deployment portfolio -n portfolio

# Check image pull
kubectl describe pod <pod-name> -n portfolio | grep -A 20 "Events:"

# Verify ACR connection
az acr repository list --name portfolioacr
```

---

## 7️⃣ Clean Up Commands

```bash
# Delete pod (triggers restart)
kubectl delete pod <pod-name> -n portfolio

# Delete deployment
kubectl delete deployment portfolio -n portfolio

# Delete all resources in namespace
kubectl delete all -n portfolio

# Delete namespace (removes all resources)
kubectl delete namespace portfolio

# Destroy all Terraform resources
cd terraform && terraform destroy -auto-approve

# Delete SSH key file
rm -f jenkins_key.pem

# Clean terraform cache
rm -rf .terraform terraform.tfstate* .terraformrc
```

---

## 8️⃣ Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| `kubectl: command not found` | Install kubectl: `brew install kubectl` |
| `terraform: command not found` | Install terraform: `brew install terraform` |
| `az: command not found` | Install Azure CLI: `brew install azure-cli` |
| Port 5173 already in use | `npm run dev -- --port 3000` |
| Cannot SSH to Jenkins | Check security group (port 22 open) |
| ACR login fails | Check credentials: `az acr credential show --name portfolioacr` |
| Pod won't start | Check logs: `kubectl logs <pod-name> -n portfolio` |
| Ingress not working | Check: `kubectl get ingress -n portfolio` |
| ArgoCD out of sync | Force sync: Click "Sync" button in UI |
| Jenkins webhook not firing | Check GitHub webhook delivery logs |

---

## 9️⃣ File Locations

```bash
# Terraform files
📁 portfolio-infra/terraform/
   ├── main.tf              # Orchestration
   ├── variables.tf         # Input variables
   ├── outputs.tf           # Output values
   ├── terraform.tfvars     # Configuration
   └── modules/             # Reusable modules

# Kubernetes manifests
📁 portfolio-infra/k8s/
   ├── namespace.yaml       # Namespace
   ├── deployment.yaml      # Pod deployment
   ├── service.yaml         # Internal service
   ├── ingress.yaml         # External routing
   └── argocd-app.yaml      # GitOps config

# Jenkins
📁 portfolio-app/
   └── Jenkinsfile          # CI/CD pipeline

# Application
📁 portfolio-app/
   ├── src/                 # React source
   ├── public/              # Static assets
   ├── Dockerfile           # Container image
   └── package.json         # Dependencies
```

---

## 🔟 Important IPs & URLs

```bash
# Get all important information
terraform output

# Specific outputs
terraform output jenkins_url              # Jenkins
terraform output acr_login_server         # ACR
terraform output kubectl_config_command   # kubectl setup
kubectl get svc -n ingress-nginx          # LoadBalancer IP

# Example:
# Jenkins: http://20.x.x.x:8080
# ACR: portfolioacr.azurecr.io
# LoadBalancer: 20.y.y.y
# Portal: https://portal.azure.com
```

---

## Cost Monitoring

```bash
# Check daily costs
az costmanagement query --timeframe TheLastMonth --granularity Monthly

# View by resource
az resource list --output table

# Estimate before apply
terraform plan -json | grep '"type"'
```

---

## Useful Links

- **Azure Portal:** https://portal.azure.com
- **GitHub:** https://github.com/YOUR_USERNAME
- **Jenkins:** http://JENKINS_IP:8080
- **ArgoCD:** https://localhost:8443 (with port-forward)
- **Terraform Docs:** https://registry.terraform.io
- **Kubernetes Docs:** https://kubernetes.io/docs
- **ArgoCD Docs:** https://argoproj.github.io/argo-cd

---

## 📞 Need Help?

1. Check DEPLOYMENT_GUIDE.md for detailed steps
2. Check logs: `kubectl logs deployment/portfolio -n portfolio`
3. Describe resources: `kubectl describe pod <name> -n portfolio`
4. Check Terraform state: `terraform state list`
5. Review Azure Portal for resource status

**Remember:** Save this card somewhere safe! 📌
