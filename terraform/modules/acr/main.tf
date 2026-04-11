# ─────────────────────────────────────────────
# Azure Container Registry
# ─────────────────────────────────────────────
resource "azurerm_container_registry" "main" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true  # Required for Jenkins to push images

  tags = {
    project    = "portfolio"
    managed_by = "terraform"
  }
}

# ─────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────
output "acr_id" {
  value = azurerm_container_registry.main.id
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  value     = azurerm_container_registry.main.admin_username
  sensitive = true
}

output "acr_admin_password" {
  value     = azurerm_container_registry.main.admin_password
  sensitive = true
}
