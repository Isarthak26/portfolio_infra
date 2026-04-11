terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  # Remote state backend (Azure Storage)
  # Uncomment after running storage module first
  # backend "azurerm" {
  #   resource_group_name  = "portfolio-rg"
  #   storage_account_name = "portfoliotfstate"   # change to your unique name
  #   container_name       = "tfstate"
  #   key                  = "portfolio.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# ─────────────────────────────────────────────
# Resource Group
# ─────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    project     = "portfolio"
    environment = "production"
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────
# Module: Storage (Terraform state backend)
# ─────────────────────────────────────────────


# ─────────────────────────────────────────────
# Module: Virtual Network
# ─────────────────────────────────────────────
module "vnet" {
  source = "./modules/vnet"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = var.vnet_name
  vnet_address_space  = var.vnet_address_space
  aks_subnet_cidr     = var.aks_subnet_cidr
  jenkins_subnet_cidr = var.jenkins_subnet_cidr
}

# ─────────────────────────────────────────────
# Module: Azure Container Registry (ACR)
# ─────────────────────────────────────────────
module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  registry_name       = var.registry_name
}

# ─────────────────────────────────────────────
# Module: AKS Cluster
# ─────────────────────────────────────────────
module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  cluster_name        = var.aks_cluster_name
  dns_prefix          = var.aks_dns_prefix
  node_count          = var.aks_node_count
  node_size           = var.aks_node_size
  aks_subnet_id       = module.vnet.aks_subnet_id
  acr_id              = module.acr.acr_id

  depends_on = [module.vnet, module.acr]
}

# ─────────────────────────────────────────────
# Module: Jenkins VM
# ─────────────────────────────────────────────
module "jenkins" {
  source = "./modules/jenkins"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  jenkins_subnet_id   = module.vnet.jenkins_subnet_id
  vm_size             = var.jenkins_vm_size
  admin_username      = var.jenkins_admin_username

  depends_on = [module.vnet]
}
