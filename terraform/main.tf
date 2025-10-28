provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "scrtp_rg" {
  name     = "scrtp-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "scrtp_aks" {
  name                = "scrtp-aks"
  location            = azurerm_resource_group.scrtp_rg.location
  resource_group_name = azurerm_resource_group.scrtp_rg.name
  dns_prefix          = "scrtpaks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2_v2"
    namespaces = ["default", "training"]
  }

  identity {
    type = "SystemAssigned"
  }

  kube_config_blocks {}
}

resource "azurerm_cosmosdb_account" "mongodb" {
  name                = "scrtp-mongo"
  location            = azurerm_resource_group.scrtp_rg.location
  resource_group_name = azurerm_resource_group.scrtp_rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"
  enable_free_tier    = true

  geo_location_block {
    location          = azurerm_resource_group.scrtp_rg.location
    failover_priority = 0
  }
}

resource "azurerm_mssql_server" "sql" {
  name                         = "scrtp-sql-server"
  resource_group_name          = azurerm_resource_group.scrtp_rg.name
  location                     = azurerm_resource_group.scrtp_rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password  # Use Key Vault in prod
}

resource "azurerm_mssql_database" "sqldb" {
  name           = "scrtp-db"
  server_id      = azurerm_mssql_server.sql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 4
  sku_name       = "S0"
}

resource "azurerm_dns_zone" "scrtp_dns" {
  name                = "scrtp.training"
  resource_group_name = azurerm_resource_group.scrtp_rg.name
}

resource "azurerm_key_vault" "scrtp_kv" {
  name                        = "scrtp-kv"
  location                    = azurerm_resource_group.scrtp_rg.location
  resource_group_name         = azurerm_resource_group.scrtp_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
}

# Outputs: cluster kubeconfig, DB endpoints, etc.
output "aks_kubeconfig" {
  value = azurerm_kubernetes_cluster.scrtp_aks.kube_config_raw
}