# Infrastructure Inheritance Pattern - Overview

## The Problem
- Infrastructure code duplicated across 7+ environment folders
- Version drift between environments (some on v1.0.8, others on v2.15.1)
- Every change requires editing multiple files
- High risk of configuration drift and inconsistencies

## The Solution
Use symlinks to achieve OOP-style inheritance for Terraform infrastructure

## How It Works

### Core Concept
- **_base/** folder contains all shared infrastructure (main.tf, variables.tf, provider.tf, datasource.tf)
- **Environment folders** (ci/, qa/, prod-live/) symlink to _base/ files
- **Symlinks in Git** - Git tracks symlinks as small pointers (not duplicate content), but Terraform reads them as complete files when running plans/applies
- **Environment-specific files** (ci-*.tf, qa-*.tf, prod-*.tf) add optional customizations
- **backend.tf** in each environment selects the TF Cloud workspace

When you run `terraform plan` in an environment folder, Terraform follows the symlinks and reads the actual _base/ files, so each environment sees the complete infrastructure as if all files were physically present.

### File Structure
```
_base/
  ├── main.tf              ← Edit ONCE, all environments inherit
  ├── variables.tf         ← Define variables ONCE
  ├── provider.tf
  └── datasource.tf

ci/
  ├── backend.tf           ← Unique workspace config
  ├── main.tf → symlink    ← Inherits from _base/
  ├── variables.tf → symlink
  ├── provider.tf → symlink
  ├── datasource.tf → symlink
  └── ci-cost-savings.tf   ← Optional CI-specific resources

qa/
  ├── backend.tf           ← Unique workspace config
  ├── [symlinks to _base/]
  ├── qa-debug.tf          ← Optional QA-specific resources
  └── qa-test-data.tf

prod-live/
  ├── backend.tf           ← Unique workspace config
  ├── [symlinks to _base/]
  ├── prod-live-backup.tf  ← Optional prod-specific resources
  ├── prod-live-monitoring.tf
  └── prod-live-variables.tf  ← Optional prod-specific variables
```

### Benefits
- **Zero duplication** - Infrastructure defined once in _base/
- **Zero drift** - All environments use identical base code via symlinks
- **Easy updates** - Change _base/main.tf once, all 7 environments updated
- **Flexible overrides** - Add environment-specific resources/variables only where needed
- **IDE compatible** - Run `terraform init` in environment folder, IDE sees all variables
- **Git friendly** - Symlinks tracked as tiny pointers, not duplicate content
- **No third-party tools** - Uses native Terraform + symlinks
- **Workflow integration** - Base changes trigger all environments, env changes trigger only that env

### Workflow Behavior
- Edit `_base/main.tf` → Orchestrator triggers CI → QA → Prod (all environments deploy)
- Edit `ci/ci-cost-savings.tf` → Only CI workflow runs
- Edit `qa/qa-debug.tf` → Only QA workflow runs
- Edit `prod-live/prod-live-monitoring.tf` → Only Prod workflow runs (with approval gate)

### Developer Experience
```bash
# Deploy to any environment
cd qa
terraform init    # IDE now sees all variables
terraform plan
terraform apply

# Update module version for ALL environments
vim ../_base/main.tf
# Change version = "2.15.1" to "2.16.0"
# All 7 environments now use v2.16.0
```

### Environment-Specific Variables
If an environment needs variables beyond the base:
- Create `{env}-variables.tf` in that environment folder
- Define additional variables there
- Use them in `{env}-*.tf` resource files
- Values come from TF Cloud workspace (same as base variables)
- Other environments don't see or need these variables

### Requirements
- Terraform 1.7.5+
- TF Cloud workspaces per environment
- Git with symlink support (all modern systems)
- GitHub Actions for CI/CD

### Migration Path
1. Create `_base/` folder with shared infrastructure
2. Run setup script to create symlinks in environment folders
3. Move environment-specific code to `{env}-*.tf` files
4. Update workflows to use orchestrator pattern
5. Test in CI, promote through environments

## Quick Stats
- **Before:** 7 copies of infrastructure code, manual sync required
- **After:** 1 base definition, automatic inheritance, optional per-env additions
- **Update time:** Edit once vs. edit 7 times
- **Drift risk:** Eliminated for base infrastructure
- **Maintenance:** Significantly reduced
