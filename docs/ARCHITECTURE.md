# 🏗️ Architecture Design Document

## Executive Summary

This document outlines the architecture decisions for the **Portfolio GitOps CI/CD Pipeline** on Azure, explaining the "why" behind each technology choice.

---

## 1. Architecture Overview

### High-Level Flow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   GitHub    │      │   Jenkins   │      │     ACR     │
│  (Source)   │ ──► │    (CI)      │ ──► │  (Registry) │
└─────────────┘      └─────────────┘      └─────────────┘
                            │                     │
                            └──────────┬──────────┘
                                       ▼
                            ┌──────────────────┐
                            │    ArgoCD (CD)   │
                            │  (portfolio-     │
                            │   infra repo)    │
                            └──────────────────┘
                                       │
                                       ▼
                            ┌──────────────────┐
                            │  AKS Cluster     │
                            │ (2x Pod Replicas)│
                            │ + Nginx Ingress  │
                            └──────────────────┘
                                       │
                                       ▼
                            ┌──────────────────┐
                            │  Users/Website   │
                            │ Load Balancer IP │
                            └──────────────────┘
```

---

## 2. Technology Decisions

### 2.1 Cloud Provider: Azure

**Why Azure?**
- ✅ Student account includes $100 free credits
- ✅ Excellent integration with Microsoft tools
- ✅ Cost-effective in India (Central India region)
- ✅ Growing adoption in Indian companies
- ✅ Strong enterprise support

**Alternatives Considered:**
- AWS: Great but more expensive for initial learning
- GCP: Good, but less adoption in India
- DigitalOcean: Simpler, but less enterprise-grade

---

### 2.2 Infrastructure: Terraform

**Why Terraform?**
- ✅ Cloud-agnostic (can migrate to AWS/GCP later)
- ✅ Modular approach (reusable modules)
- ✅ Version-controlled infrastructure
- ✅ Plan before apply (safe)
- ✅ State management (knows what exists)

**Terraform Structure:**
```
modules/
├── vnet/      → Networking foundation
├── aks/       → Kubernetes cluster
├── acr/       → Container storage
├── jenkins/   → CI/CD automation
└── storage/   → Terraform state
```

**Why Modules?**
- Reusable across environments (prod/staging/dev)
- Easy to understand
- Maintainable
- Team-friendly

---

### 2.3 Kubernetes: AKS (Azure Kubernetes Service)

**Why AKS?**
- ✅ Managed service (Azure handles control plane)
- ✅ Auto-scaling and updates
- ✅ Azure Monitor integration
- ✅ RBAC and security built-in
- ✅ Cost-effective (Standard_B2s nodes)

**Configuration:**
```yaml
Node Count: 2              # Cost-effective HA
Node Size: Standard_B2s    # 1 vCPU, 4GB RAM (~$30/node/month)
Version: 1.29              # Current stable
Network: Azure CNI         # Full networking control
```

**Why 2 Nodes?**
- ✅ High availability (one can fail)
- ✅ Zero-downtime deployments
- ✅ Cost-effective ($60-80/month)
- ❌ Less than 2: No HA, no rolling updates
- ❌ 3+: Better but overkill for portfolio

---

### 2.4 Container Registry: ACR

**Why ACR?**
- ✅ Native Azure integration
- ✅ Managed service (Azure handles scaling)
- ✅ Private by default (secure)
- ✅ AKS can pull images directly (no external auth)
- ✅ Cheap (Basic tier: ~$5/month)

**Alternative: Docker Hub**
- Docker Hub would be free
- But requires manual authentication in AKS
- Less secure (public by default)
- No image scanning built-in

---

### 2.5 CI/CD: Jenkins → ArgoCD

**Why separate CI and CD?**

This is the **GitOps principle**: Git is the single source of truth.

```
CI (Jenkins):              CD (ArgoCD):
- Build code               - Watch Git repo
- Run tests               - Sync manifests
- Build image             - No external tools in cluster
- Push to registry        - Full audit trail
- Update Git              - Easy rollback (git revert)
```

**Why Jenkins for CI?**
- ✅ Industry standard
- ✅ Flexible (Groovy scripting)
- ✅ Extensible (plugins)
- ✅ Good for Docker builds
- ✅ Webhook integration with GitHub

**Why ArgoCD for CD?**
- ✅ GitOps native
- ✅ Minimal cluster access (pull-based)
- ✅ Declarative (desired state in Git)
- ✅ Automatic rollback (easy)
- ✅ Easy to audit (everything in Git)
- ✅ Secure (cluster doesn't need Jenkins access)

---

### 2.6 Networking: Nginx Ingress + Load Balancer

**Architecture:**

```
Internet
   │
   ▼
┌─────────────────────┐
│ Azure Load Balancer │ (External IP)
├─────────────────────┤
│ Nginx Ingress Ctrl  │ (K8s ingress controller)
├─────────────────────┤
│ Portfolio Service   │ (ClusterIP, internal only)
├─────────────────────┤
│ Portfolio Pods (2x) │
└─────────────────────┘
```

**Why this structure?**
- ✅ External users hit Load Balancer IP
- ✅ Nginx routes to services
- ✅ Services route to pods
- ✅ Pods are completely internal (secure)
- ✅ Easy to scale (just change replica count)

**Why not NodePort or ClusterIP?**
- NodePort: Exposes high ports, ugly IPs
- ClusterIP: Internal only, can't reach from outside
- LoadBalancer: Clean, professional, scalable

---

### 2.7 Container Image: Multi-Stage Docker Build

**Dockerfile Strategy:**

```dockerfile
# Stage 1: Builder
FROM node:18-alpine AS builder
RUN npm ci && npm run build
# Output: dist/ folder

# Stage 2: Runtime
FROM node:18-alpine
COPY --from=builder /app/dist dist/
RUN npm install -g serve
CMD ["serve", "-s", "dist", "-l", "3000"]
```

**Why multi-stage?**
- ✅ Final image is ~100MB (much smaller)
- ✅ No build dependencies in production
- ✅ Faster deployment
- ✅ Secure (less attack surface)

**Why node:18-alpine?**
- ✅ Alpine = tiny base image (~40MB)
- ✅ Node 18 = stable LTS
- ✅ Production-ready
- ❌ Full Ubuntu = 500MB+, overkill

---

### 2.8 Security Scanning: Trivy

**Why Trivy?**
- ✅ Fast vulnerability scanner
- ✅ Scans Docker images
- ✅ Open source (free)
- ✅ CI/CD friendly
- ✅ Finds OS and package vulnerabilities

**Pipeline Integration:**
```
Build image → Trivy scan → Push to ACR
  (if critical vulns, can fail build)
```

---

### 2.9 Pod Security

**Kubernetes Security Hardening:**

```yaml
securityContext:
  runAsNonRoot: true           # No root user
  runAsUser: 1001              # Specific UID
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true # Can't modify system
  capabilities:
    drop:
      - ALL                    # No Linux capabilities

resources:
  requests:
    cpu: 100m                  # Minimum resources
    memory: 128Mi
  limits:
    cpu: 500m                  # Maximum resources
    memory: 512Mi
```

**Why?**
- ✅ Limits blast radius of container compromise
- ✅ Prevents privilege escalation
- ✅ Resource quotas prevent DoS

---

## 3. Deployment Strategy

### Rolling Updates (Zero Downtime)

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1           # 1 extra pod while updating
    maxUnavailable: 0     # Keep all pods running
```

**What happens during update:**
1. New pod spins up with new image
2. Old pod waits for new pod to be ready
3. Traffic switches to new pod
4. Old pod terminates
5. No downtime! ✅

---

### Health Checks

```yaml
livenessProbe:    # Is container alive?
  httpGet /
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:   # Is container ready for traffic?
  httpGet /
  initialDelaySeconds: 10
  periodSeconds: 5
```

**Benefits:**
- ✅ Detects dead containers
- ✅ Doesn't send traffic to unhealthy pods
- ✅ Auto-restarts failed pods

---

## 4. Cost Optimization

### Monthly Breakdown

| Resource | Cost | Notes |
|----------|------|-------|
| AKS (2x B2s) | $60-80 | Cheapest tier that's not underpowered |
| ACR | $5 | Basic tier |
| Load Balancer | $15 | Standard SKU |
| Jenkins VM | $10-15 | Standard_B2s (same as AKS) |
| Storage Account | <$1 | For Terraform state |
| **Total** | **~$100/month** | Covered by free credits! |

### Ways to Save More

1. **Use Free Tier:** Azure for Students = $100/month free
2. **Delete when not using:** `terraform destroy`
3. **Spot instances:** For non-critical workloads
4. **Reserved instances:** For long-term (1-3 year commitment)

---

## 5. High Availability & Disaster Recovery

### High Availability (HA)

**What's protected:**
- ✅ Pod crashes → Auto-restart
- ✅ Node fails → Pod moves to other node
- ✅ Image push fails → Old image still works
- ✅ Update fails → Auto-rollback available

**What's NOT protected:**
- ❌ Entire AKS cluster fails (Azure SLA covers this)
- ❌ All nodes die simultaneously (unlikely with managed service)

**Improvement:** Multi-region setup (expensive, for enterprise)

### Disaster Recovery

**Easy rollback:**
```bash
# Git revert triggers Jenkins
git revert HEAD
git push

# Jenkins builds old version
# ArgoCD syncs old version
# Website reverts instantly
```

**No backup needed!** Git is the backup.

---

## 6. Scalability

### Horizontal Scaling (more pods)

**Current:**
```yaml
replicas: 2  # 2 copies running
```

**To scale up:**
```bash
# Change replicas
kubectl scale deployment portfolio -n portfolio --replicas=5

# Or update deployment.yaml and push to git
# ArgoCD auto-syncs
```

**Benefits:**
- ✅ Each pod handles more requests
- ✅ Load Balancer distributes traffic
- ✅ Zero downtime

### Vertical Scaling (bigger nodes)

```bash
# Change terraform.tfvars
aks_node_size = "Standard_D2s_v3"  # Bigger VM

# Re-apply
terraform apply
```

---

## 7. Monitoring & Observability

### What's Monitored

**Pod health:**
- Liveness probe (is it alive?)
- Readiness probe (is it serving traffic?)

**Logs:**
```bash
kubectl logs deployment/portfolio -n portfolio
```

**Optional:** Azure Monitor (costs extra)

---

## 8. Comparison: Other Approaches

### Why not...?

#### 1. Kubernetes without ArgoCD?

```
❌ Manual kubectl apply
   - Error-prone
   - No version control
   - Hard to audit
   - No easy rollback

✅ ArgoCD (this approach)
   - Git-driven
   - Full audit trail
   - Easy rollback
   - Automated sync
```

#### 2. Terraform without Modules?

```
❌ Single main.tf (1000+ lines)
   - Hard to understand
   - Not reusable
   - Team unfriendly

✅ Modular approach
   - Clear separation
   - Reusable
   - Easy to test
```

#### 3. Docker without multi-stage?

```
❌ 500MB image
   - Slow to push/pull
   - More vulnerabilities
   - Higher costs

✅ Multi-stage (~100MB)
   - Fast
   - Secure
   - Cheap
```

---

## 9. Future Improvements

### Optional Enhancements

1. **HTTPS/SSL**
   ```bash
   # Install cert-manager
   # Setup Let's Encrypt
   ```

2. **Monitoring**
   ```bash
   # Enable Azure Monitor
   # Add Prometheus + Grafana
   ```

3. **Autoscaling**
   ```bash
   # Horizontal Pod Autoscaler (HPA)
   # Scale based on CPU/memory
   ```

4. **Custom Domain**
   ```bash
   # Point domain to Load Balancer IP
   # Update ingress.yaml
   ```

5. **Multi-region**
   ```bash
   # Deploy to multiple Azure regions
   # Higher availability
   ```

---

## 10. Learning Outcomes

This architecture teaches:

✅ **Cloud Infrastructure**
- Networking (VNet, subnets, security groups)
- Managed services (AKS, ACR)
- Resource provisioning

✅ **Containerization**
- Docker multi-stage builds
- Image optimization
- Registry management

✅ **Kubernetes**
- Deployments, services, ingress
- Health checks, resource limits
- RBAC and security

✅ **CI/CD**
- Webhook automation
- Container building
- Image scanning

✅ **GitOps**
- Git as source of truth
- Automated deployment
- Easy rollback

✅ **Infrastructure as Code**
- Terraform modules
- Version control
- Reproducibility

---

## Summary

This architecture provides:
- ✅ **Professional:** Enterprise-grade practices
- ✅ **Scalable:** Easy to grow
- ✅ **Secure:** Security hardening throughout
- ✅ **Cost-effective:** ~$100/month (covered by free credits)
- ✅ **Automated:** Minimal manual intervention
- ✅ **Learnable:** Every component has clear purpose

Perfect for demonstrating DevOps engineering skills! 🚀

---

**Questions?** See DEPLOYMENT_GUIDE.md for detailed setup.
