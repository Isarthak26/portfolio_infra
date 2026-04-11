# ─────────────────────────────────────────────
# General
# ─────────────────────────────────────────────
variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "portfolio-rg"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "centralindia"
}

# ─────────────────────────────────────────────
# Networking
# ─────────────────────────────────────────────
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "portfolio-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR block for the AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "jenkins_subnet_cidr" {
  description = "CIDR block for the Jenkins subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# ─────────────────────────────────────────────
# AKS
# ─────────────────────────────────────────────
variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "portfolio-aks"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "portfolio"
}

variable "aks_node_count" {
  description = "Initial number of AKS nodes"
  type        = number
  default     = 1
}

variable "aks_node_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B1s"
  
}



# ─────────────────────────────────────────────
# ACR
# ─────────────────────────────────────────────
variable "registry_name" {
  description = "Name of the Azure Container Registry (must be globally unique, alphanumeric only)"
  type        = string
  default     = "portfolioacr"
}

# ─────────────────────────────────────────────
# Jenkins
# ─────────────────────────────────────────────
variable "jenkins_vm_size" {
  description = "VM size for the Jenkins server"
  type        = string
  default     = "Standard_B2s"
}

variable "jenkins_admin_username" {
  description = "Admin username for Jenkins VM"
  type        = string
  default     = "azureuser"
}

# ─────────────────────────────────────────────
# Storage
# ─────────────────────────────────────────────
variable "storage_account_name" {
  description = "Name of the Storage Account for Terraform state (must be globally unique, 3-24 lowercase alphanumeric chars)"
  type        = string
  default     = "portfoliotfstate"
}
