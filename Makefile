.PHONY: install-gcloud login-gcloud create-env create-credentials terraform-init terraform-plan terraform-apply docker-up dbt-run streamlit-run setup

VENV = .venv
BIN = $(VENV)/bin
PYTHON = $(BIN)/python3
PIP = $(BIN)/pip
DBT = $(BIN)/dbt
STREAMLIT = $(BIN)/streamlit
DOTENV = $(BIN)/dotenv

# Install Google Cloud CLI
install-gcloud:
	@echo "Installing Google Cloud CLI..."
	curl https://sdk.cloud.google.com | bash
	@echo "Please restart your shell or run 'source ~/.bashrc' to add gcloud to your PATH"

# Login to Google Cloud | if you are not on WSL you can likely remove the --no-launch-browser option for convenience
login-gcloud:
	@echo "Logging into Google Cloud..."
	gcloud auth login --no-launch-browser
	gcloud config set project $(GCP_PROJECT_ID)
	gcloud auth application-default login --no-launch-browser

# Create .env file with necessary environment variables
create-env:
	@echo "Creating .env file..."
	@echo "# Google Cloud Configuration" > .env
	@echo "GCP_PROJECT_ID=$(GCP_PROJECT_ID)" >> .env
	@echo "GCP_REGION=$(GCP_REGION)" >> .env
	@echo "BUCKET_NAME=$(BUCKET_NAME)" >> .env
	@echo "GOOGLE_APPLICATION_CREDENTIALS=./credentials.json" >> .env
	@echo ".env file created. Please ensure credentials.json is in the project root."

# Create GCP Service Account credentials
create-credentials:
	@echo "Creating GCP Service Account credentials..."
	gcloud iam service-accounts keys create credentials.json \
		--iam-account=who-pipeline-service-account@$(GCP_PROJECT_ID).iam.gserviceaccount.com
	@echo "credentials.json created successfully."

# Initialize Terraform
terraform-init:
	@echo "Initializing Terraform..."
	cd terraform && terraform init

# Plan Terraform changes
terraform-plan:
	@echo "Planning Terraform changes..."
	cd terraform && terraform plan -var="project_id=$(GCP_PROJECT_ID)" -var="region=$(GCP_REGION)"

# Apply Terraform changes
terraform-apply:
	@echo "Applying Terraform changes..."
	cd terraform && terraform apply -var="project_id=$(GCP_PROJECT_ID)" -var="region=$(GCP_REGION)" -auto-approve

# Start Docker Compose services (Kestra)
docker-up:
	@echo "Starting Docker Compose services..."
	sudo docker-compose up -d

python-setup:
	python3 -m venv $(VENV)
	$(PIP) install -r requirements.txt
	$(DBT) deps --project-dir dbt --profiles-dir dbt

# Run DBT models
dbt-build:
	@echo "Running DBT models..."
	$(DOTENV) run $(DBT) build --project-dir dbt --profiles-dir dbt

# Run Streamlit app
streamlit-run:
	@echo "Running Streamlit app..."
	$(STREAMLIT) run app.py

# Full setup (requires environment variables to be set)
setup: create-env terraform-init terraform-apply create-credentials docker-up
	@echo "Setup complete. Open Kestra and execute the flow at"

transform: python-setup dbt-build

view: streamlit-run