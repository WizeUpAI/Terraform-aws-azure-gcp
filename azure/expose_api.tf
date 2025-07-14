
# ----------------------
# Azure Variables
# ----------------------
variable "location" {
  default = "westeurope"
}
variable "docker_image" {
  description = "Docker image for FastAPI app"
}
variable "domain_name" {
  description = "Custom domain name, e.g., example.com"
}
provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "rg" {
  name     = "fastapi-rg"
  location = var.location
}
# ----------------------
# Azure Resources
# ----------------------

resource "azurerm_log_analytics_workspace" "log" {
  name                = "fastapi-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                       = "fastapi-env"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id
}

resource "azurerm_container_app" "fastapi" {
  name                         = "fastapi-app"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "fastapi"
      image  = var.docker_image
      cpu    = 0.5
      memory = "1.0Gi"

      probes {
        type     = "Liveness"
        http_get {
          path = "/health"
          port = 80
        }
        initial_delay_seconds = 3
        period_seconds        = 30
      }
    }
    ingress {
      external_enabled = true
      target_port      = 80
      transport        = "auto"
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

# Azure Front Door
resource "azurerm_cdn_frontdoor_profile" "fd_profile" {
  name                = "fastapi-fd-profile"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "fd_endpoint" {
  name                     = "fastapi-endpoint"
  profile_name             = azurerm_cdn_frontdoor_profile.fd_profile.name
  resource_group_name      = azurerm_resource_group.rg.name
  enabled                  = true
}

resource "azurerm_cdn_frontdoor_origin_group" "fd_origin_group" {
  name                     = "fastapi-origin-group"
  profile_name             = azurerm_cdn_frontdoor_profile.fd_profile.name
  resource_group_name      = azurerm_resource_group.rg.name
  session_affinity_enabled = false

  health_probe {
    path     = "/health"
    protocol = "Http"
    interval_in_seconds = 30
  }
}

resource "azurerm_cdn_frontdoor_origin" "fd_origin" {
  name                          = "fastapi-origin"
  profile_name                  = azurerm_cdn_frontdoor_profile.fd_profile.name
  resource_group_name           = azurerm_resource_group.rg.name
  origin_group_name             = azurerm_cdn_frontdoor_origin_group.fd_origin_group.name
  host_name                     = azurerm_container_app.fastapi.latest_revision_fqdn
  http_port                     = 80
  https_port                    = 443
  priority                      = 1
  weight                        = 1000
  enabled                       = true
}

resource "azurerm_cdn_frontdoor_route" "fd_route" {
  name                          = "fastapi-route"
  profile_name                  = azurerm_cdn_frontdoor_profile.fd_profile.name
  resource_group_name           = azurerm_resource_group.rg.name
  endpoint_name                 = azurerm_cdn_frontdoor_endpoint.fd_endpoint.name
  origin_group_name             = azurerm_cdn_frontdoor_origin_group.fd_origin_group.name
  accepted_protocols            = ["Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "MatchRequest"
  https_redirect_enabled        = true
  enabled                       = true

  rules_engine {
    name = "aad-auth-rule"
  }
}

# Azure DNS
resource "azurerm_dns_zone" "zone" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "api"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  record              = azurerm_cdn_frontdoor_endpoint.fd_endpoint.host_name
}

# AAD auth would be configured manually via Azure Front Door portal or Bicep

[Azure DNS]
   ↓
[Azure Front Door (HTTPS)]
   ↓
[AAD Auth via Front Door]
   ↓
[Azure Container App (FastAPI Docker)]

#Résumé de ce que fait ce code
#Élément	Description
#Container App	Exécute l'API FastAPI (Docker)
#Azure Front Door	Load balancer mondial avec HTTPS + auth
#DNS (Azure DNS)	Fournit le nom api.mondomaine.com
#Azure AD Auth	Possible via Front Door Rules Engine (via UI)
#TLS	Automatique via Front Door


#✅ Rôles des services Azure utilisés
#Service Azure	                    Rôle dans l’architecture
#azurerm_resource_group	Groupe      logique pour organiser tous les services Azure associés.
#azurerm_log_analytics_workspace	Collecte les logs de la Container App (monitoring, debug, audit).
#azurerm_container_app_environment	Environnement d’exécution pour héberger la Container App (FastAPI).
#azurerm_container_app	            Déploie et exécute l’API FastAPI à partir d’une image Docker.
#azurerm_cdn_frontdoor_profile	    Crée un Azure Front Door (CDN global) pour exposer l’API au public.
#azurerm_cdn_frontdoor_endpoint	    Définit un point d’entrée DNS global pour accéder à l’API.
#azurerm_cdn_frontdoor_origin_group	Groupe de backends vers lesquels Front Door peut router le trafic.
#azurerm_cdn_frontdoor_origin	    Définit la Container App comme origine (backend) de Front Door.
#azurerm_cdn_frontdoor_route	    Configure le routing HTTP/HTTPS de Front Door vers votre API.
#azurerm_dns_zone	                Crée une zone DNS publique (ex: example.com) hébergée sur Azure.
#azurerm_dns_cname_record	        Mappe api.example.com vers l’URL du Front Door (CNAME).
#identity { type = "SystemAssigned" }	Attribue une identité managée à la Container App (utile pour auth AAD).

#Authentification via Azure Front Door + AAD
#Bien que Azure Front Door ne gère pas directement l’OAuth2 dans le code Terraform, il permet :
#Mécanisme	Rôle
#Rules Engine (portal ou Bicep)	Redirige les utilisateurs vers Azure AD si non authentifiés
#Identité managée (MSI)	Permet à la Container App d'appeler d’autres services Azure de façon sécurisée
#Azure AD (hors Terraform)	Gère les sessions, groupes, autorisations (OAuth2 ou OpenID Connect)
#
#🎯 L'intégration complète avec Azure AD se fait souvent via le portail Azure ou via Bicep/ARM Templates (plus puissant que Terraform pour Front Door Auth à ce jour).


#🌐 Routage et accès externe
#Élément	        Rôle
#Azure Front Door	Load balancer global, DNS, HTTPS, cache, auth + SSL offloading
#Azure DNS	        Permet d’avoir un nom de domaine api.mondomaine.com
#CNAME record	    Associe le sous-domaine api au endpoint public Front Door
#TLS/SSL	        Géré automatiquement par Azure Front Door (pas besoin de certificat)


#🔎 Monitoring et observabilité
#Élément	                        Rôle
#azurerm_log_analytics_workspace	Collecte et analyse des logs (accès, erreurs, performances)
#Container App Logs	                Affiche les logs de l’API FastAPI (via print, uvicorn, etc.)