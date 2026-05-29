# Infrastructure Inheritance Pattern (Symlinks)

## The Problem This Solves

**Before:** Multiple duplicate folders, version drift, update nightmare
**After:** Define once, symlink everywhere, optional overrides

## Structure

```
example-service/
├── _base/                          ← Define infrastructure ONCE
│   ├── main.tf                     ← Spot EC2 instance
│   ├── variables.tf                ← All variable definitions
│   ├── provider.tf
│   └── datasource.tf
│
├── dev/                            ← Dev environment
│   ├── backend.tf                  ← Unique (workspace config)
│   ├── main.tf → ../_base/main.tf           (symlink to base)
│   ├── variables.tf → ../_base/variables.tf (symlink to base)
│   ├── provider.tf → ../_base/provider.tf   (symlink to base)
│   ├── datasource.tf → ../_base/datasource.tf (symlink to base)
│   └── dev-scaling.tf              ← Dev-specific additions
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
└── prod/                           ← Prod environment
    ├── backend.tf                  ← Unique (workspace config)
    ├── main.tf → ../_base/main.tf           (symlink to base)
    ├── variables.tf → ../_base/variables.tf (symlink to base)
    ├── provider.tf → ../_base/provider.tf   (symlink to base)
    ├── datasource.tf → ../_base/datasource.tf (symlink to base)
    ├── prod-backup.tf              ← Prod-specific backup infrastructure
    ├── prod-monitoring.tf          ← Prod-specific enhanced monitoring
    └── prod-variables.tf           ← Prod-specific variable definitions
```

## How It Works

### Symlinks = Shared Infrastructure

All environments symlink to `_base/` files:
- Edit `_base/main.tf` → All environments see it
- Update infrastructure once → All environments get it
- Zero duplication, zero drift

### backend.tf = Workspace Selection

Each environment has unique `backend.tf`:
```hcl
# qa/backend.tf
workspaces {
  name = "example-service-qa"
}
```

This controls which TF Cloud workspace (and thus which variable values).

### Environment-specific files = Optional Additions

Add files prefixed with environment name for environment-specific resources:
- `dev-scaling.tf` → Dev-specific log group
- `qa-debug.tf` → Debug resources, test data (QA only)
- `prod-backup.tf` → EBS volume, alarms (Prod only)
- `prod-monitoring.tf` → SNS alerts, CloudWatch (Prod only)
- `prod-variables.tf` → Additional variables only prod needs

These files can use all base variables (they're symlinked). You can also add environment-specific variable definitions that only that environment needs.

## Commands

```bash
# Deploy to QA
cd example-service/qa
terraform init
terraform apply

# Deploy to Prod
cd example-service/prod
terraform init
terraform apply

# Update base infrastructure
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
mkdir staging

# Create unique backend
cat > staging/backend.tf << 'EOL'
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "your-org"
    workspaces {
      name = "example-service-staging"
    }
  }
  required_version = ">= 1.7.5"
}
EOL

# Symlink base files
cd staging
ln -s ../_base/main.tf main.tf
ln -s ../_base/variables.tf variables.tf
ln -s ../_base/provider.tf provider.tf
ln -s ../_base/datasource.tf datasource.tf

# Optional: Add environment-specific resources
touch staging-config.tf  # If staging needs something unique
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
cd prod
touch prod-variables.tf
```

```hcl
# prod/prod-variables.tf
variable "alarm_email" {
  description = "Email address for production alerts"
  type        = string
}

variable "data_volume_size" {
  description = "Size of additional EBS volume in GB"
  type        = number
  default     = 100
}
```

Then use them in your environment-specific resource files:

```hcl
# prod/prod-backup.tf
resource "aws_ebs_volume" "data" {
  availability_zone = "${var.region}a"
  size              = var.data_volume_size  # Uses prod-specific variable
  encrypted         = true

  tags = merge(var.tags, {
    Name = "${var.service_name}-${var.environment}-data"
  })
}
```

Values for these environment-specific variables come from the TF Cloud workspace, just like base variables.

## GitHub Actions Workflows

The pattern includes workflow orchestration for automated deployments:

```
.github/workflows/
├── example-service-base.yml   ← Orchestrator (watches _base/)
├── example-service-dev.yml    ← Dev workflow (watches dev/)
├── example-service-qa.yml     ← QA workflow (watches qa/)
└── example-service-prod.yml   ← Prod workflow (watches prod/)
```

**Workflow behavior:**
- Edit `_base/main.tf` → Base orchestrator triggers all environments (Dev → QA → Prod sequentially)
- Edit `dev/dev-scaling.tf` → Only dev workflow runs
- Edit `qa/qa-debug.tf` → Only QA workflow runs
- Edit `prod/prod-monitoring.tf` → Only prod workflow runs

Each environment workflow:
- Can be triggered manually via `workflow_dispatch`
- Can be called from orchestrator via `workflow_call`
- Runs `terraform plan` on PRs, `terraform apply` on merge to main
- Prod includes GitHub environment protection for required reviewers

## Key Benefits

- ✅ Define infrastructure once in `_base/`
- ✅ Define variables once (or add per-environment as needed)
- ✅ Variable values from TF Cloud workspace
- ✅ Each environment can add resources/variables
- ✅ Environment files use base variables seamlessly
- ✅ IDE shows variables (no errors after terraform init)
- ✅ Clean folder organization
- ✅ Zero duplication, zero drift
- ✅ Workflow orchestration for base changes
- ✅ Individual workflows for environment-specific changes
