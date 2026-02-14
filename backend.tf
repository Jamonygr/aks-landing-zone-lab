# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Backend Configuration - Azure Storage Remote State                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stakslabtfstate"
    container_name       = "tfstate"
    key                  = "aks-landing-zone-lab.tfstate"
  }
}
