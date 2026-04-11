# ─────────────────────────────────────────────
# AKS Cluster
# ─────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix


  # System node pool
  default_node_pool {
  name                = "systempool"
  node_count          = 1
  vm_size             = "Standard_B2s"
  vnet_subnet_id      = var.aks_subnet_id
  os_disk_size_gb     = 30
  type                = "VirtualMachineScaleSets"

  enable_auto_scaling = false

  node_labels = {
    "role" = "system"
  }
}

  # Use SystemAssigned managed identity (no need to manage service principals)
  identity {
    type = "SystemAssigned"
  }

  # Azure CNI for full networking control
  network_profile {
    network_plugin     = "azure"
    load_balancer_sku  = "standard"
    outbound_type      = "loadBalancer"
    service_cidr       = "10.1.0.0/16"
    dns_service_ip     = "10.1.0.10"
  }

  # RBAC enabled
  role_based_access_control_enabled = true

  # Automatic channel upgrades - set to none to control manually


  tags = {
    project     = "portfolio"
    environment = "production"
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────
# Grant AKS permission to pull from ACR
# ─────────────────────────────────────────────
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

# ─────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────
output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}
