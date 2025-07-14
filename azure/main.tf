provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}


# ----------------------
# Azure Resources
# ----------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "azure-vm"
  resource_group_name = var.azure_resource_group
  location            = var.azure_location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = var.azure_vm_password

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = var.azure_storage_account_name
  resource_group_name      = var.azure_resource_group
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = var.azure_sql_server_name
  resource_group_name          = var.azure_resource_group
  location                     = var.azure_location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.azure_sql_password
}

resource "azurerm_function_app" "function" {
  name                       = "azure-function"
  resource_group_name        = var.azure_resource_group
  location                   = var.azure_location
  app_service_plan_id        = azurerm_app_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  os_type                    = "linux"
  runtime_stack              = "python"
  version                    = "3.10"
}

resource "azurerm_machine_learning_workspace" "ml" {
  name                = "azure-ml"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group
}

resource "azurerm_synapse_workspace" "synapse" {
  name                = "synapse-workspace"
  resource_group_name = var.azure_resource_group
  location            = var.azure_location
  sql_administrator_login          = "adminuser"
  sql_administrator_login_password = var.azure_sql_password
  storage_data_lake_gen2_filesystem_id = azurerm_storage_account.storage.id
}