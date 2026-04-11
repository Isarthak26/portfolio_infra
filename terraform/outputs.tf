# ─────────────────────────────────────────────
# Resource Group
# ─────────────────────────────────────────────
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

# ─────────────────────────────────────────────
# AKS
# ─────────────────────────────────────────────
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "kubectl_config_command" {
  description = "Command to configure kubectl for the AKS cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}

# ─────────────────────────────────────────────
# ACR
# ─────────────────────────────────────────────
output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = module.acr.acr_login_server
}

output "acr_admin_username" {
  description = "Admin username for the ACR"
  value       = module.acr.acr_admin_username
  sensitive   = true
}

# ─────────────────────────────────────────────
# Jenkins
# ─────────────────────────────────────────────
output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins VM"
  value       = module.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins web UI URL"
  value       = "http://${module.jenkins.public_ip}:8080"
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins VM"
  value       = "ssh -i jenkins_key.pem azureuser@${module.jenkins.public_ip}"
}

# ─────────────────────────────────────────────
# Storage
# ─────────────────────────────────────────────


# ─────────────────────────────────────────────
# Networking
# ─────────────────────────────────────────────
output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = module.vnet.vnet_id
}
