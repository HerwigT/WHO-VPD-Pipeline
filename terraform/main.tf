terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "dataproc.googleapis.com",
    "iam.googleapis.com"
  ])
  project = var.project_id
  service = each.value

  disable_on_destroy = false 
}

# 1. Create the Service Account
resource "google_service_account" "pipeline_sa" {
  account_id   = "who-pipeline-service-account"
  display_name = "WHO Pipeline Service Account"
  project      = var.project_id
  depends_on = [google_project_service.enabled_apis]
}

# 2. Assign Roles (IAM)
locals {
  roles = [
    "roles/storage.admin",    # Manage Data Lake (GCS)
    "roles/bigquery.admin",   # Manage Data Warehouse (BQ)
    "roles/dataproc.worker",   # Allow Spark to run on Dataproc
    "roles/dataproc.editor",
    "roles/iam.serviceAccountUser"
  ]
}

resource "google_project_iam_member" "sa_roles" {
  for_each = toset(local.roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# 1. Bronze Layer (Data Lake - GCS & External Tables)
resource "google_storage_bucket" "bronze_lake" {
  name          = "who_bronze_lake_${var.project_id}"
  location      = var.region
  uniform_bucket_level_access = true
  force_destroy = true
  depends_on	= [google_project_service.enabled_apis]
}

resource "google_bigquery_dataset" "bronze_dataset" {
  dataset_id = "who_bronze"
  project    = var.project_id
  location   = var.region
  depends_on = [google_project_service.enabled_apis]
}

# 2. Silver Layer (Warehouse - BigQuery Dataset)
# Used for cleaned tables (e.g., standardized column names, casted types)
resource "google_bigquery_dataset" "silver_dataset" {
  dataset_id = "who_silver"
  project    = var.project_id
  location   = var.region
  depends_on = [google_project_service.enabled_apis]
}

# 3. Gold Layer (Warehouse - BigQuery Dataset)
# Used for the final Dashboard tables (e.g., joined incidence & vax rates)
resource "google_bigquery_dataset" "gold_dataset" {
  dataset_id = "who_gold"
  project    = var.project_id
  location   = var.region
  depends_on = [google_project_service.enabled_apis]
}

