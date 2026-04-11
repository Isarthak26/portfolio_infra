# ─────────────────────────────────────────────
# Storage Account for Terraform State
# ─────────────────────────────────────────────
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"   # Locally redundant (cheapest)

  # Security settings
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  tags = {
    project    = "portfolio"
    purpose    = "terraform-state"
    managed_by = "terraform"
  }
}

# ─────────────────────────────────────────────
# Blob Container for .tfstate file
# ─────────────────────────────────────────────
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# ─────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────
output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "container_name" {
  value = azurerm_storage_container.tfstate.name
}
