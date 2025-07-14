provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project
  region      = var.gcp_region
}
# ----------------------
# GCP Resources
# ----------------------
resource "google_compute_instance" "gce_instance" {
  name         = "gce-instance"
  machine_type = "e2-micro"
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}

resource "google_storage_bucket" "gcs_bucket" {
  name     = var.gcp_gcs_bucket_name
  location = var.gcp_region
}

resource "google_sql_database_instance" "cloudsql" {
  name             = "cloudsql-instance"
  database_version = "MYSQL_8_0"
  region           = var.gcp_region

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_cloudfunctions_function" "gcf" {
  name        = "cloud-function"
  runtime     = "python310"
  entry_point = "hello_world"
  source_archive_bucket = google_storage_bucket.gcs_bucket.name
  source_archive_object = "function-source.zip"
  trigger_http = true
}

resource "google_vertex_ai_workbench_instance" "notebook" {
  name  = "vertex-notebook"
  location = var.gcp_region
  machine_type = "n1-standard-1"
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = "multicloud_bq"
  location   = var.gcp_region
}