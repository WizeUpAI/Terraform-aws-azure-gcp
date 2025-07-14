#                [User Browser]
#                       │
#                       ▼
#            ┌──────────────────────┐
#            │   Cloud Load Balancer│  ← HTTPS + TLS
#            └────────┬─────────────┘
#                     │
#          [Identity-Aware Proxy (IAP)]
#                     │  🔒 Authentifie avec Google Identity
#                     ▼
#              [Cloud Run (FastAPI)]
#                     │
#             Docker container HTTPS
#                     ▼
#           [Cloud Logging / Monitoring]

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)
}
# ----------------------
# GCP variables
# ----------------------
variable "project_id" {}
variable "region" {}
variable "credentials_file" {}
variable "docker_image" {}
variable "domain_name" {}
variable "dns_zone" {}
variable "iap_client_id" {}
variable "iap_client_secret" {}
variable "allowed_group_email" {}
# ----------------------
# GCP Resources
# ----------------------
resource "google_cloud_run_service" "fastapi" {
  name     = "fastapi"
  location = var.region

  template {
    spec {
      containers {
        image = var.docker_image
        ports {
          container_port = 8080
        }
      }
    }
  }

  traffics {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "authenticated" {
  location = var.region
  service  = google_cloud_run_service.fastapi.name
  role     = "roles/run.invoker"
  member   = "group:${var.allowed_group_email}"
}

resource "google_compute_region_network_endpoint_group" "neg" {
  name                  = "fastapi-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.fastapi.name
  }
}

resource "google_compute_backend_service" "fastapi_backend" {
  name                  = "fastapi-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_region_network_endpoint_group.neg.id
  }

  iap {
    oauth2_client_id     = var.iap_client_id
    oauth2_client_secret = var.iap_client_secret
  }
}

resource "google_compute_url_map" "url_map" {
  name            = "fastapi-url-map"
  default_service = google_compute_backend_service.fastapi_backend.id
}

resource "google_compute_target_http_proxy" "proxy" {
  name    = "fastapi-proxy"
  url_map = google_compute_url_map.url_map.id
}

resource "google_compute_global_address" "lb_ip" {
  name = "fastapi-ip"
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = "fastapi-forwarding-rule"
  port_range = "80"
  target     = google_compute_target_http_proxy.proxy.id
  ip_address = google_compute_global_address.lb_ip.address
}

resource "google_dns_record_set" "dns" {
  name         = "api.${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone
  rrdatas      = [google_compute_global_address.lb_ip.address]
}

#Voici l’architecture résumée ✅ sur Google Cloud Platform (GCP) pour exposer une API FastAPI (Docker) avec :
#🚀 Cloud Run (serverless container) pour exécuter FastAPI
#🌐 External HTTPS Load Balancer
#🌍 Nom de domaine personnalisé via Cloud DNS
#🔐 Authentification avec IAP (Identity-Aware Proxy)

#Composants GCP utilisés :
#Composant	Rôle
#Cloud Run	Héberge l’API FastAPI dans un conteneur Docker
#Cloud Load Balancing	Load balancer global avec HTTPS et support IAP
#Cloud IAP	Ajoute une authentification sécurisée via comptes Google
#Cloud DNS	Gère les noms de domaine personnalisés (ex: api.example.com)
#SSL/TLS	Automatique via Google-managed certificates
#Google Cloud IAM	Contrôle d’accès à Cloud Run + IAP
🚀 Flux utilisateur (HTTPS, Authentifié, Sécurisé)

#L’utilisateur accède à https://api.mondomaine.com :
#Le Load Balancer redirige vers Cloud Run
#IAP intercepte la requête et demande une connexion Google
#Si l’utilisateur est autorisé, la requête est transmise à FastAPI
#FastAPI répond à la requête, protégée derrière IAP