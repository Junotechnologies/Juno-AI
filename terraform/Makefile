# Makefile for Juno Analytics Terraform Infrastructure
# Usage: make <target>

.PHONY: help init-dev init-prod plan-dev plan-prod apply-dev apply-prod destroy-dev fmt validate clean

# Default target
help:
	@echo "Juno Analytics Terraform Commands"
	@echo "=================================="
	@echo "Setup:"
	@echo "  make init-dev        - Initialize Terraform for DEV environment"
	@echo "  make init-prod       - Initialize Terraform for PROD environment"
	@echo ""
	@echo "Planning:"
	@echo "  make plan-dev        - Preview changes for DEV"
	@echo "  make plan-prod       - Preview changes for PROD"
	@echo ""
	@echo "Deployment:"
	@echo "  make apply-dev       - Deploy to DEV environment"
	@echo "  make apply-prod      - Deploy to PROD environment (requires confirmation)"
	@echo ""
	@echo "Maintenance:"
	@echo "  make fmt             - Format all Terraform files"
	@echo "  make validate        - Validate Terraform configuration"
	@echo "  make output          - Show current outputs"
	@echo "  make clean           - Clean Terraform cache"
	@echo ""
	@echo "Danger:"
	@echo "  make destroy-dev     - ⚠️  Destroy DEV infrastructure"

# Initialize for DEV
init-dev:
	@echo "🔧 Initializing Terraform for DEV environment..."
	terraform init -backend-config=environments/backend-dev.tfvars

# Initialize for PROD
init-prod:
	@echo "🔧 Initializing Terraform for PROD environment..."
	terraform init -backend-config=environments/backend-prod.tfvars

# Plan changes for DEV
plan-dev:
	@echo "📋 Planning DEV deployment..."
	terraform plan -var-file="environments/dev.tfvars"

# Plan changes for PROD
plan-prod:
	@echo "📋 Planning PROD deployment..."
	terraform plan -var-file="environments/prod.tfvars"

# Apply changes to DEV
apply-dev:
	@echo "🚀 Deploying to DEV environment..."
	terraform apply -var-file="environments/dev.tfvars"

# Apply changes to PROD (with confirmation)
apply-prod:
	@echo "⚠️  PRODUCTION DEPLOYMENT ⚠️"
	@echo "This will modify production infrastructure."
	@read -p "Are you sure? [yes/no] " REPLY; \
	if [ "$$REPLY" = "yes" ]; then \
		terraform apply -var-file="environments/prod.tfvars"; \
	else \
		echo "Deployment cancelled."; \
	fi

# Destroy DEV infrastructure
destroy-dev:
	@echo "⚠️  DESTROYING DEV INFRASTRUCTURE ⚠️"
	@read -p "Are you absolutely sure? [yes/no] " REPLY; \
	if [ "$$REPLY" = "yes" ]; then \
		terraform destroy -var-file="environments/dev.tfvars"; \
	else \
		echo "Destruction cancelled."; \
	fi

# Format all Terraform files
fmt:
	@echo "✨ Formatting Terraform files..."
	terraform fmt -recursive

# Validate Terraform configuration
validate:
	@echo "✅ Validating Terraform configuration..."
	terraform validate

# Show outputs
output:
	@echo "📊 Terraform Outputs:"
	terraform output

# Output as JSON
output-json:
	@echo "📊 Terraform Outputs (JSON):"
	terraform output -json

# Clean Terraform cache
clean:
	@echo "🧹 Cleaning Terraform cache..."
	rm -rf .terraform
	rm -rf .terraform.lock.hcl
	rm -f *.tfplan
	rm -rf .terraform/tmp

# Create environment-specific config files from examples
setup-configs:
	@echo "📝 Creating configuration files from examples..."
	@if [ ! -f environments/dev.tfvars ]; then \
		cp environments/dev.tfvars.example environments/dev.tfvars; \
		echo "✅ Created environments/dev.tfvars"; \
	else \
		echo "ℹ️  environments/dev.tfvars already exists"; \
	fi
	@if [ ! -f environments/prod.tfvars ]; then \
		cp environments/prod.tfvars.example environments/prod.tfvars; \
		echo "✅ Created environments/prod.tfvars"; \
	else \
		echo "ℹ️  environments/prod.tfvars already exists"; \
	fi
	@if [ ! -f environments/backend-dev.tfvars ]; then \
		cp environments/backend-dev.tfvars.example environments/backend-dev.tfvars; \
		echo "✅ Created environments/backend-dev.tfvars"; \
	else \
		echo "ℹ️  environments/backend-dev.tfvars already exists"; \
	fi
	@if [ ! -f environments/backend-prod.tfvars ]; then \
		cp environments/backend-prod.tfvars.example environments/backend-prod.tfvars; \
		echo "✅ Created environments/backend-prod.tfvars"; \
	else \
		echo "ℹ️  environments/backend-prod.tfvars already exists"; \
	fi
	@echo ""
	@echo "⚠️  IMPORTANT: Edit the .tfvars files with your actual values before running 'make init-dev'"

# Full setup for first-time use
first-time-setup: setup-configs
	@echo ""
	@echo "🎉 First-time setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Edit environments/dev.tfvars with your project-specific values"
	@echo "2. Edit environments/backend-dev.tfvars with your GCS bucket name"
	@echo "3. Run: make init-dev"
	@echo "4. Run: make plan-dev"
	@echo "5. Run: make apply-dev"
