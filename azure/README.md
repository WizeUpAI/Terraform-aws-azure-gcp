🌐 Azure Databases principales
```
Type	                Service Azure	                Cas d’usage principal
Relationnel (SQL)	    Azure SQL Database	            Base SQL managée, apps web, SaaS
SQL managé scalable	    Azure SQL Managed Instance	    Migration base on-premise, compatibilité SQL Server complète
Open Source SQL	        Azure Database for PostgreSQL	Apps, analytics, géospatial
Open Source SQL	        Azure Database for MySQL	    Apps web, CMS
NoSQL (clé-valeur)	    Azure Cosmos DB	                Multi-modèle NoSQL (DocumentDB, Cassandra, Gremlin, Table)
NoSQL Document	        Azure Cosmos DB (API MongoDB)	MongoDB compatible
Cache In-memory	        Azure Cache for Redis	        Caching, pub/sub, sessions
Time Series	            Azure Time Series Insights	    IoT, séries temporelles
Graph	                Azure Cosmos DB (Gremlin API)	Base graphe
Data Warehouse	        Azure Synapse Analytics	        Big data, analyse
```

Terraform Azure code pour chaque base

1️⃣ Azure SQL Database (single instance)
```
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-sql-example"
  location = "eastus"
}

resource "azurerm_sql_server" "sqlserver" {
  name                         = "sqlserverexample"
  resource_group_name          = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  version                     = "12.0"
  administrator_login         = "sqladmin"
  administrator_login_password = "ChangeMe123!"
}

resource "azurerm_sql_database" "sqldb" {
  name                = "mydatabase"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sqlserver.name
  sku_name            = "Basic"
}
```
2️⃣ Azure SQL Managed Instance (MI)
```
resource "azurerm_sql_managed_instance" "mi" {
  name                         = "sqlmanagedinstanceexample"
  resource_group_name          = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  administrator_login         = "sqladmin"
  administrator_login_password = "ChangeMe123!"
  subnet_id                   = azurerm_subnet.subnet.id
  sku_name                    = "GP_Gen5_2"
  storage_size_in_gb          = 32
  vcores                      = 2
}
```
Note: Il faut créer un VNet et subnet spécifique.

3️⃣ Azure Database for PostgreSQL (Single Server)
```
resource "azurerm_postgresql_server" "pg" {
  name                = "psqlserverexample"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name            = "B_Gen5_1"
  version             = "13"
  administrator_login = "psqladmin"
  administrator_login_password = "ChangeMe123!"

  storage_mb          = 5120
  backup_retention_days = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled   = true
  public_network_access_enabled = true
}
```
4️⃣ Azure Database for MySQL (Single Server)
```
resource "azurerm_mysql_server" "mysql" {
  name                = "mysqlserverexample"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name            = "B_Gen5_1"
  version             = "8.0"
  administrator_login = "mysqladmin"
  administrator_login_password = "ChangeMe123!"

  storage_mb          = 5120
  backup_retention_days = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled   = true
  public_network_access_enabled = true
}
```

5️⃣ Azure Cosmos DB (multi modèle)
```
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cosmosdbexample"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  consistency_policy {
    consistency_level       = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}
```

6️⃣ Azure Cache for Redis
```
resource "azurerm_redis_cache" "redis" {
  name                = "rediscacheexample"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 1
  family              = "C"
  sku_name            = "Basic"
}
```

7️⃣ Azure Time Series Insights (pré-requis : Event Hubs + Storage)
Terraform n'a pas encore un provider complet pour Time Series Insights. On crée généralement via portal ou API. On peut créer un Event Hub et un Storage Account via Terraform.

Notes générales
Remplace les mots de passe par des variables ou secrets.
Configure bien les réseaux, sous-réseaux, règles de firewall, et accès privés/publics.
Certains services demandent un VNet (ex: Managed Instance).
Pour Azure Cosmos DB, tu peux changer l’API (MongoDB, Cassandra, Gremlin...) via la propriété kind.