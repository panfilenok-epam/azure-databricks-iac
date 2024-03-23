terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.89.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "1.35.0"
    }
  }
  required_version = ">= 1.1.0"
  backend "azurerm" {
  }
}

provider "azurerm" {
  use_oidc = true
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-databricks-poc"
  location = "westeurope"
}

resource "azurerm_databricks_workspace" "db_workspace" {
  name                = "my-databricks-workspace"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"

  custom_parameters {
    no_public_ip = true
  }
}

provider "databricks" {
  alias                       = "azure"
  host                        = azurerm_databricks_workspace.db_workspace.workspace_url
  azure_workspace_resource_id = azurerm_databricks_workspace.db_workspace.id
}

resource "time_sleep" "wait_for_workspace" {
  create_duration = "30s"
  depends_on      = [azurerm_databricks_workspace.db_workspace]
}

resource "databricks_cluster" "db_cluster" {
  cluster_name            = "my-databricks-cluster"
  spark_version           = "13.3.x-scala2.12"
  node_type_id            = "Standard_DS3_v2"
  autotermination_minutes = 10
  autoscale {
    min_workers = 1
    max_workers = 1
  }
  provider = databricks.azure
}

output "databricks_host" {
  value = azurerm_databricks_workspace.db_workspace.workspace_url
}

output "databricks_azurerm_databricks_workspace_id" {
  value = azurerm_databricks_workspace.db_workspace.id
}