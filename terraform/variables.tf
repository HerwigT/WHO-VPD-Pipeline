variable "project_id" {
  description = "Your GCP Project ID"
  type        = string
}

variable "region" {
  description = "Region for resources"
  default     = "us-central1"
}

variable "storage_class" {
  description = "Storage class for the GCS bucket"
  default     = "STANDARD"
}
