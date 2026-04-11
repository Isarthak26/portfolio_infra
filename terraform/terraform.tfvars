# ══════════════════════════════════════════════════════
# ⚠️  CUSTOMIZE THESE VALUES BEFORE RUNNING TERRAFORM  ⚠️
# ══════════════════════════════════════════════════════

# General
resource_group_name = "portfolio-rg"
location            = "centralindia"   # Change if needed: eastus, westeurope, etc.

# Networking
vnet_name           = "portfolio-vnet"
vnet_address_space  = "10.0.0.0/16"
aks_subnet_cidr     = "10.0.1.0/24"
jenkins_subnet_cidr = "10.0.2.0/24"

# AKS Cluster
aks_cluster_name   = "portfolio-aks"
aks_dns_prefix     = "portfolio"
aks_node_count     = 2
aks_node_size      = "Standard_B2s"   # ~$30/node/month in Central India


# ⚠️ ACR name MUST be globally unique (only lowercase letters + numbers)
registry_name = "portfolioacr112"        # e.g. sarthakacr, myportfolioacr2024

# Jenkins
jenkins_vm_size        = "Standard_B2s"
jenkins_admin_username = "azureuser"

# ⚠️ Storage account MUST be globally unique (3-24 lowercase alphanumeric)
storage_account_name = "portfoliotfstate112"   # e.g. sarthaktfstate2024
