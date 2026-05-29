# Infrastructure Inheritance Pattern (Symlinks)

## The Problem This Solves

**Before:** 7 duplicate folders, version drift, update nightmare
**After:** Define once, symlink everywhere, optional overrides

## Structure

```
example-service/
├── _base/                          ← Define infrastructure ONCE
│   ├── main.tf                     ← example-module v2.15.1
│   ├── variables.tf                ← All variable definitions
│   ├── provider.tf
│   └── datasource.tf
│
├── ci/                             ← CI environment
│   ├── backend.tf                  ← Unique (workspace config)
│   ├── main.tf → ../_base/main.tf           (symlink to base)
│   ├── variables.tf → ../_base/variables.tf (symlink to base)
│   ├── provider.tf → ../_base/provider.tf   (symlink to base)
│   ├── datasource.tf → ../_base/datasource.tf (symlink to base)
│   └── ci-cost-savings.tf         ← CI-specific additions
│
├── qa/                             ← QA environment
│   ├── backend.tf                  ← Unique (workspace config)
│   ├── main.tf → ../_base/main.tf           (symlink to base)
│   ├── variables.tf → ../_base/variables.tf (symlink to base)
│   ├── provider.tf → ../_base/provider.tf   (symlink to base)
│   ├── datasource.tf → ../_base/datasource.tf (symlink to base)
│   ├── qa-debug.tf                 ← QA-specific debug resources
│   └── qa-test-data.tf             ← QA-specific test data generators
│
└── prod-live/                      ← Prod environment
    ├── backend.tf                  ← Unique (workspace config)
    ├── main.tf → ../_base/main.tf           (symlink to base)
    ├── variables.tf → ../_base/variables.tf (symlink to base)
    ├── provider.tf → ../_base/provider.tf   (symlink to base)
    ├── datasource.tf → ../_base/datasource.tf (symlink to base)
    ├── prod-live-backup.tf         ← Prod-specific backup infrastructure
    ├── prod-live-monitoring.tf     ← Prod-specific enhanced monitoring
    └── prod-live-variables.tf      ← Prod-specific variable definitions
```

## How It Works

### Symlinks = Shared Infrastructure

All environments symlink to `_base/` files:
- Edit `_base/main.tf` → All 7 environments see it
- Update module version once → All environments get it
- Zero duplication, zero drift

### backend.tf = Workspace Selection

Each environment has unique `backend.tf`:
```hcl
# qa/backend.tf
workspaces {
  name = "your-product-document-scanning-terraform-qa"
}
```

This controls which TF Cloud workspace (and thus which variable values).

### Environment-specific files = Optional Additions

Add files prefixed with environment name for environment-specific resources:
- `qa-debug.tf` → Debug queue, logs (QA only)
- `prod-live-backup.tf` → Backup vault, plan (Prod only)
- `prod-live-monitoring.tf` → Enhanced monitoring (Prod only)
- `prod-live-variables.tf` → Additional variables only prod needs

These files can use all base variables (they're symlinked). You can also add environment-specific variable definitions that only that environment needs.

## Commands

```bash
# Deploy to QA
cd example-service/qa
terraform init
terraform apply

# Deploy to Prod
cd example-service/prod-live
terraform init
terraform apply

# Update module version
# Edit _base/main.tf once
# All environments get the update
```

## Benefits

✅ **Zero duplication** - Infrastructure defined once in `_base/`  
✅ **Zero drift** - Symlinks ensure all environments use same code  
✅ **Per-environment workspace** - backend.tf controls TF Cloud workspace  
✅ **Optional overrides** - Add `override-*.tf` only where needed  
✅ **IDE works** - VSCode sees symlinked variables, no red squiggles  
✅ **Git-friendly** - Symlinks tracked, clones work automatically  
✅ **Standard Terraform** - No third-party tools required  

## Creating New Environment

```bash
cd example-service
mkdir tcpci

# Create unique backend
cat > tcpci/backend.tf << 'EOL'
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "your-org"
    workspaces {
      name = "your-product-document-scanning-terraform-tcpci"
    }
  }
  required_version = ">= 1.7.5"
}
EOL

# Symlink base files
cd tcpci
ln -s ../_base/main.tf main.tf
ln -s ../_base/variables.tf variables.tf
ln -s ../_base/provider.tf provider.tf
ln -s ../_base/datasource.tf datasource.tf

# Optional: Add environment-specific resources
touch tcpci-regional.tf  # If tcpci needs something unique
```

## Adding Environment-Specific Resources

```bash
# Create new environment-specific file
cd qa
touch qa-performance-testing.tf
```

```hcl
# qa/qa-performance-testing.tf
# Can use all base variables (they're symlinked)

resource "aws_lambda_function" "load_generator" {
  function_name = "${var.service_name}-${var.environment}-load-generator"
  # Uses var.service_name, var.environment from base/variables.tf
  tags = var.tags
}
```

## Adding Environment-Specific Variables

If an environment needs additional variables beyond the base, create an environment-specific variables file:

```bash
# Create additional variables for prod only
cd prod-live
touch prod-live-variables.tf
```

```hcl
# prod-live/prod-live-variables.tf
variable "backup_retention_days" {
  description = "How long to keep backups in days"
  type        = number
}

variable "alarm_email" {
  description = "Email address for production alerts"
  type        = string
}
```

Then use them in your environment-specific resource files:

```hcl
# prod-live/prod-live-backup.tf
resource "aws_backup_plan" "this" {
  name = "${var.service_name}-${var.environment}-backup-plan"
  rule {
    rule_name = "daily_backup"
    target_vault_name = aws_backup_vault.this.name
    schedule = "cron(0 5 ? * * *)"
    lifecycle {
      delete_after = var.backup_retention_days  # Uses prod-specific variable
    }
  }
}
```

Values for these environment-specific variables come from the TF Cloud workspace, just like base variables.

## GitHub Actions Workflows

The pattern includes workflow orchestration for automated deployments:

```
.github/workflows/
├── example-service-base.yml        ← Orchestrator (watches _base/)
├── example-service-ci.yml          ← CI workflow (watches ci/)
├── example-service-qa.yml          ← QA workflow (watches qa/)
└── example-service-prod-live.yml   ← Prod workflow (watches prod-live/)
```

**Workflow behavior:**
- Edit `_base/main.tf` → Base orchestrator triggers all environments (CI → QA → Prod sequentially)
- Edit `ci/ci-cost-savings.tf` → Only CI workflow runs
- Edit `qa/qa-debug.tf` → Only QA workflow runs
- Edit `prod-live/prod-live-monitoring.tf` → Only Prod workflow runs

Each environment workflow:
- Can be triggered manually via `workflow_dispatch`
- Can be called from orchestrator via `workflow_call`
- Runs `terraform plan` on PRs, `terraform apply` on merge to main
- Prod includes GitHub environment protection for required reviewers

## This Is What You Wanted

- ✅ Define infrastructure once
- ✅ Define variables once  
- ✅ Values from TF Cloud workspace
- ✅ Each environment can add resources/variables
- ✅ Environment files use base variables
- ✅ IDE shows variables (no errors after terraform init)
- ✅ Clean folder organization
- ✅ No duplication, no drift
- ✅ Workflow orchestration for base changes
- ✅ Individual workflows for environment-specific changes
