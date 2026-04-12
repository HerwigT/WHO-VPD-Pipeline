output "service_account_email" {
  value = google_service_account.pipeline_sa.email
}

output "bronze_bucket_name" {
  value = google_storage_bucket.bronze_lake.name
}
