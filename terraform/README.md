# Juno Analytics Terraform Infrastructure

This Terraform project manages the complete GCP infrastructure for the Juno Analytics platform, including BigQuery datasets, Cloud Functions, Pub/Sub topics, and monitoring.

## 📁 Project Structure

```
terraform/
├── main.tf                 # Main entry point, calls all modules
├── variables.tf            # Root-level variable definitions
├── outputs.tf              # Root-level outputs
├── providers.tf            # Provider configurations
├── .gitignore             # Git ignore rules
├── environments/          # Environment-specific configurations
│   ├── dev.tfvars.example
│   ├── prod.tfvars.example
│   ├── backend-dev.tfvars.example
│   └── backend-prod.tfvars.example
└── modules/               # Reusable Terraform modules
    ├── bigquery/         # BigQuery datasets (Bronze, Silver, Gold, Quality)
    ├── cloud_functions/  # Cloud Functions (Gen 2)
    ├── iam/             # Service accounts and IAM roles
    ├── storage/         # GCS buckets
    ├── scheduler/       # Cloud Scheduler jobs
    ├── pubsub/          # Pub/Sub topics and subscriptions
    └── monitoring/      # Alert policies and monitoring
```

## 🚀 Quick Start

### Prerequisites

1. **Install Terraform** (>= 1.5.0)
   ```bash
   brew install terraform
   ```

2. **Authenticate with GCP**
   ```bash
   gcloud auth application-default login
   gcloud config set project junoplus-dev
   ```

3. **Create GCS Bucket for Terraform State**
   ```bash
   # For DEV
   gsutil mb -p junoplus-dev -l us-central1 gs://junoplus-dev-terraform-state/
   gsutil versioning set on gs://junoplus-dev-terraform-state/
   
   # For PROD
   gsutil mb -p juno-9dfb6 -l us-central1 gs://juno-9dfb6-terraform-state/
   gsutil versioning set on gs://juno-9dfb6-terraform-state/
   ```

### Initial Setup

1. **Copy example files to actual configuration files**
   ```bash
   cd terraform/environments
   cp dev.tfvars.example dev.tfvars
   cp backend-dev.tfvars.example backend-dev.tfvars
   ```

2. **Edit the configuration files** with your actual values
   ```bash
   # Edit dev.tfvars with your project-specific values
   vim dev.tfvars
   
   # Edit backend-dev.tfvars with your GCS bucket name
   vim backend-dev.tfvars
   ```

3. **Initialize Terraform** (from the `terraform/` directory)
   ```bash
   cd ..  # Back to terraform/ root
   terraform init -backend-config=environments/backend-dev.tfvars
   ```

## 💻 Common Commands

### Plan (Preview Changes)
```bash
# For DEV
terraform plan -var-file="environments/dev.tfvars"

# For PROD
terraform plan -var-file="environments/prod.tfvars"
```

### Apply (Deploy Infrastructure)
```bash
# For DEV
terraform apply -var-file="environments/dev.tfvars"

# For PROD (requires confirmation)
terraform apply -var-file="environments/prod.tfvars"
```

### Destroy (Remove All Resources)
```bash
# ⚠️ DANGEROUS - Only use in dev
terraform destroy -var-file="environments/dev.tfvars"
```

### Format and Validate
```bash
terraform fmt -recursive
terraform validate
```

### Show Current State
```bash
terraform show
terraform state list
```

## 🔐 Security Best Practices

### ✅ DO's

1. **Never commit secrets**
   - `.tfvars` files are in `.gitignore`
   - Use Secret Manager for sensitive values
   - Pass secrets via environment variables:
     ```bash
     export TF_VAR_notification_email="alerts@example.com"
     terraform apply -var-file="environments/dev.tfvars"
     ```

2. **Use GCS backend**
   - State files are stored in Google Cloud Storage
   - Enables version control and team collaboration
   - Prevents state file conflicts

3. **Use dedicated service accounts**
   - Don't use personal accounts for Terraform
   - Create a service account with minimum required permissions
   - ```bash
     gcloud iam service-accounts create terraform-admin \
       --display-name="Terraform Admin"
     ```

4. **Enable deletion protection in production**
   - Set `bq_delete_protection = true` in prod.tfvars
   - Prevents accidental deletion of BigQuery datasets

### ❌ DON'Ts

1. **Never hardcode project IDs or secrets** in `.tf` files
2. **Never use local state** (`terraform.tfstate`) in production
3. **Never run `terraform destroy`** on production without backup
4. **Don't make manual changes** in GCP Console after deploying via Terraform

## 🏗️ Architecture

### Medallion Architecture (Bronze → Silver → Gold)

- **Bronze Layer**: Raw data from Firestore (via BigQuery streaming)
- **Silver Layer**: Cleansed, validated, enriched data
- **Gold Layer**: Aggregated, analytics-ready data for dashboards and ML
- **Quality Layer**: Data quality metrics and monitoring

### Cloud Functions Pipeline

1. **refresh-silver**: Transforms Bronze → Silver (scheduled daily)
2. **refresh-gold**: Transforms Silver → Gold (scheduled weekly)
3. **quality-check**: Validates data quality (scheduled hourly)
4. **ml-snapshot**: Creates ML training snapshots (scheduled weekly)

### Scheduling

All functions are triggered by Cloud Scheduler jobs with configurable cron schedules defined in `dev.tfvars` or `prod.tfvars`.

## 📊 Outputs

After deployment, Terraform will output:

- Service account email
- BigQuery dataset IDs
- Cloud Function URLs
- GCS bucket names
- Pub/Sub topic names
- Scheduler job names

Access outputs:
```bash
terraform output
terraform output -json > outputs.json
```

## 🔄 Switching Between Environments

### From DEV to PROD

1. **Re-initialize with PROD backend**
   ```bash
   terraform init -reconfigure -backend-config=environments/backend-prod.tfvars
   ```

2. **Plan with PROD variables**
   ```bash
   terraform plan -var-file="environments/prod.tfvars"
   ```

3. **Apply (with caution)**
   ```bash
   terraform apply -var-file="environments/prod.tfvars"
   ```

### From PROD back to DEV

```bash
terraform init -reconfigure -backend-config=environments/backend-dev.tfvars
```

## 🧪 Testing Changes

Always test in DEV first:

```bash
# 1. Plan and review
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan

# 2. Apply the plan
terraform apply dev.tfplan

# 3. Verify in GCP Console

# 4. If successful, replicate to PROD
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
terraform apply prod.tfplan
```

## 🧭 State & Workspace Safety Runbook

Use this sequence to avoid cross-environment state drift (for example, DEV plan reading PROD state).

### 1) Full logout and clean re-auth

```bash
gcloud auth revoke --all --quiet || true
gcloud auth application-default revoke --quiet || true

gcloud auth login
gcloud auth application-default login

gcloud config set project junoplus-dev
```

### 2) Ensure backend bucket exists (DEV)

```bash
gsutil mb -p junoplus-dev -l us-central1 gs://junoplus-dev-terraform-state/
gsutil versioning set on gs://junoplus-dev-terraform-state/
```

### 3) Initialize Terraform with DEV backend config

From `terraform/`:

```bash
terraform init -reconfigure -backend-config=environments/backend-dev.tfvars
```

### 4) Verify and isolate workspaces

```bash
terraform workspace list
terraform workspace show
```

If currently in `prod`, create/select `dev` workspace:

```bash
terraform workspace select dev 2>/dev/null || terraform workspace new dev
terraform workspace select dev
```

### 5) Backup state before switching workflows (recommended)

```bash
ts=$(date +%Y%m%d-%H%M%S)
mkdir -p .state-backups

terraform workspace select prod >/dev/null
terraform state pull > .state-backups/prod-${ts}.tfstate

terraform workspace select default >/dev/null
terraform state pull > .state-backups/default-${ts}.tfstate

terraform workspace select dev >/dev/null
```

### 6) Run DEV plan safely

```bash
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
```

Expected safe pattern for a fresh DEV workspace:
- Mostly `to add`
- `0 to destroy`
- No mass replacements from `*-prod` to `*-dev`

### Standard command blocks

#### DEV

```bash
cd /Users/roviandsouza/Documents/JunoAI/terraform
terraform workspace select dev
terraform init -reconfigure -backend-config=environments/backend-dev.tfvars
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
# terraform apply dev.tfplan
```

#### PROD

```bash
cd /Users/roviandsouza/Documents/JunoAI/terraform
gcloud config set project juno-9dfb6
terraform workspace select prod
terraform init -reconfigure -backend-config=environments/backend-prod.tfvars
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
# terraform apply prod.tfplan
```

### Safety checks before apply

```bash
terraform workspace show
terraform state list | head -30
```

Confirm:
- Workspace matches target environment (`dev` or `prod`)
- Resource names in state match target env suffix/pattern
- Plan does **not** propose cross-environment replacement

## 🛠️ Troubleshooting

### Error: Backend configuration changed
```bash
terraform init -reconfigure -backend-config=environments/backend-dev.tfvars
```

### Error: State lock
Someone else is running Terraform. Wait for them to finish, or force unlock (use with caution):
```bash
terraform force-unlock <LOCK_ID>
```

### Error: Resources already exist
Import existing resources:
```bash
terraform import google_bigquery_dataset.bronze junoplus-dev:junoplus_analytics_dev
```

### Provider version conflicts
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade
```

## 📝 Making Changes

### Adding a New Module

1. Create directory: `modules/new_module/`
2. Add files: `main.tf`, `variables.tf`, `outputs.tf`
3. Call from root `main.tf`:
   ```hcl
   module "new_module" {
     source = "./modules/new_module"
     # ... variables
   }
   ```

### Adding a New Cloud Function

1. Add function code to `../bigquery_medallion_migration/functions/new_function/`
2. Update `modules/cloud_functions/main.tf` with new resource
3. Update `modules/scheduler/main.tf` to add scheduler job
4. Run `terraform apply`

## 🔍 Monitoring

View deployed monitoring:
- [Cloud Console - Monitoring](https://console.cloud.google.com/monitoring)
- Alert policies are created automatically
- Email notifications (configure via `notification_email` variable)

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/new-module`
2. Make changes
3. Test in DEV: `terraform plan -var-file="environments/dev.tfvars"`
4. Commit: `git commit -m "Add new module"`
5. Push and create PR

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices)
- [Cloud Functions Gen 2](https://cloud.google.com/functions/docs/2nd-gen)

## ⚠️ Important Notes

1. **State file encryption**: GCS buckets automatically encrypt state files
2. **Cost optimization**: Dev resources use smaller instances and can be destroyed when not in use
3. **Backup**: Always backup state file before major changes
4. **Documentation**: Update this README when adding new modules

## 📞 Support

For issues or questions:
- Open an issue in the repository
- Contact the infrastructure team
- Review the [Architecture Gap Analysis](../bigquery_medallion_migration/ARCHITECTURE_GAP_ANALYSIS.md)
