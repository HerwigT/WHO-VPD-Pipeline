# WHO-VPD-Pipeline
An ETL pipeline for the WHO GHO OData API. Automates extraction of fragmented disease incidence and vaccination records (DTP/Polio 3).

# Setup
- Install gcloud cli
- run ```bash gcloud auth application-default login```

🛠️ Infrastructure Setup
This project uses Terraform to manage Google Cloud Platform (GCP) resources and follows the Medallion Architecture (Bronze GCS bucket, Silver/Gold BigQuery datasets).

1. Prerequisites

Ensure you have the following tools installed:
- Google Cloud SDK (gcloud CLI)
- Terraform (v1.0+)

2. Google Cloud Initialization

- Create a Project: Log into the GCP Console and create a new project. Note your Project ID.
- Enable Billing: Ensure billing is attached to the project (required for BigQuery and Dataproc APIs).
- Authenticate CLI:
```bash
gcloud auth login
gcloud auth application-default login
```

3. Provision Infrastructure (Terraform)

Navigate to the terraform/ directory and execute the following:

```bash
# Initialize Terraform and download Google providers
terraform init

# Review the execution plan
terraform plan -var="project_id=YOUR_PROJECT_ID"

# Deploy the infrastructure
terraform apply -var="project_id=YOUR_PROJECT_ID"
```
4. Service Account & Security

After the infrastructure is provisioned, you must generate a key for the Service Account so the Python/Spark scripts can interact with GCP:

Generate JSON Key:

```bash
gcloud iam service-accounts keys create credentials.json \
    --iam-account=who-pipeline-service-account@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

5. Verified Resources

Once complete, the following resources will be active:

- GCS Bucket: who_bronze_lake_<project_id> (Raw Data Lake)
- BigQuery Dataset: who_silver (Cleaned Tables)
- BigQuery Dataset: who_gold (Reporting Tables)
- Service Account: who-pipeline-service-account with Storage and BigQuery Admin roles.

# Ingest Data

- run:
```bash
export BUCKET_NAME=YOUR_BUCKET_NAME
docker-compose up -d
```
- Open Kestra on localhost:8080
- Run flow data-ingestion

# 🛡️ Data Ethics & Compliance
## Sensitive Data & Privacy

This project adheres to high standards of data privacy and ethical engineering practices:

- No PII: This pipeline only processes anonymized, aggregated global health data at the country and regional levels. No Personally Identifiable Information (PII) is accessed, stored, or processed.
- Source Integrity: Data is fetched directly from the official WHO GHO OData API to ensure data lineage and integrity.

## Data Use Disclaimer

- Official Source: All epidemiological and immunization data are provided by the World Health Organization (World Health Organization).
- License: This data is used under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Intergovernmental Organization (CC BY-NC-SA 3.0 IGO) license.
- Non-Endorsement: This repository is an independent data engineering project for analytical and educational purposes. It is not an official WHO product, and the findings do not represent the official views of the WHO.
- Terms: Use of the data is subject to the [WHO Data Use Agreement](https://www.who.int/about/policies/publishing/copyright).
