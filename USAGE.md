# Usage Guide

There are two ways to use this pattern: manually with Terraform CLI, or automated with GitHub Actions workflows.

## Option 1: Manual Terraform Apply (Recommended for Testing)

This is the simplest way to test and deploy. No CI/CD required.

### Prerequisites
- Terraform >= 1.7.5 installed
- AWS credentials configured
- Terraform Cloud account (optional, can use local backend instead)

### Steps

1. **Navigate to an environment folder:**
```bash
cd example-service/dev
```

2. **Initialize Terraform:**
```bash
terraform init
```

This step:
- Downloads providers
- Configures the backend
- Follows symlinks to read all files (base + environment-specific)

3. **Review the plan:**
```bash
terraform plan
```

Terraform sees:
- All files from `_base/` (via symlinks)
- Environment-specific files (`dev-*.tf`)
- The unique `backend.tf` for this environment

4. **Apply the changes:**
```bash
terraform apply
```

5. **Deploy to another environment:**
```bash
cd ../qa
terraform init
terraform plan
terraform apply
```

Each environment:
- Uses the same base infrastructure (via symlinks)
- Has its own unique workspace (`backend.tf`)
- Can have optional additions (`{env}-*.tf` files)

### Using Local Backend Instead of Terraform Cloud

If you don't want to use Terraform Cloud, update `backend.tf`:

```hcl
# dev/backend.tf
terraform {
  backend "local" {
    path = "terraform-dev.tfstate"
  }
  required_version = ">= 1.7.5"
}
```

## Option 2: Automated with GitHub Actions

For production use, automate deployments with GitHub Actions workflows.

### How It Works

The repository includes example workflows:
- `example-service-base.yml` - Orchestrator that triggers all environments when base changes
- `example-service-dev.yml` - Deploys dev when dev-specific files change
- `example-service-qa.yml` - Deploys QA when QA-specific files change
- `example-service-prod.yml` - Deploys prod when prod-specific files change (requires approval)

### Workflow Behavior

**When you edit `_base/main.tf`:**
- Base orchestrator workflow runs
- Triggers dev → qa → prod sequentially
- All environments get the update

**When you edit `dev/dev-scaling.tf`:**
- Only dev workflow runs
- Other environments unaffected

**When you edit `prod/prod-monitoring.tf`:**
- Only prod workflow runs
- Requires manual approval (GitHub environment protection)

### Setup Required

1. **Create GitHub Environments:**
   - Go to repository Settings → Environments
   - Create: `dev`, `qa`, `prod`
   - For `prod`, add required reviewers

2. **Add Secrets:**
   - `TF_API_TOKEN` - Terraform Cloud API token

3. **Push to main branch:**
   - Changes to `_base/` trigger all environments
   - Changes to specific env trigger only that env

### Customizing Workflows

The example workflows use standard Terraform commands:
```yaml
- terraform init
- terraform plan
- terraform apply -auto-approve
```

You can replace these with:
- Your organization's reusable workflows
- Additional validation steps
- Security scanning
- Cost estimation tools
- Whatever your team needs

## Comparison

| Aspect | Manual CLI | GitHub Actions |
|--------|-----------|----------------|
| Setup | None | Requires workflows + secrets |
| Speed | Instant | Depends on runners |
| Approval | Manual review | GitHub environment protection |
| Audit Trail | Local logs | GitHub workflow history |
| Best For | Testing, Development | Production, Team collaboration |

## Tips

### IDE Integration

After running `terraform init` in an environment folder, your IDE (VS Code, IntelliJ, etc.) will:
- Recognize all variables from base (via symlinks)
- Provide autocomplete
- Show no errors for environment-specific files using base variables

### Updating All Environments

To update infrastructure across all environments:

1. Edit `_base/main.tf`
2. Either:
   - **Manual**: Run terraform apply in each environment folder
   - **Automated**: Push to main, orchestrator triggers all

### Adding New Environment

```bash
# 1. Create folder
mkdir example-service/staging

# 2. Create unique backend
cat > example-service/staging/backend.tf << 'EOF'
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
EOF

# 3. Create symlinks
cd example-service/staging
ln -s ../_base/main.tf main.tf
ln -s ../_base/variables.tf variables.tf
ln -s ../_base/provider.tf provider.tf
ln -s ../_base/datasource.tf datasource.tf

# 4. (Optional) Add staging-specific resources
touch staging-config.tf

# 5. Deploy
terraform init
terraform apply
```

Or use the provided script:
```bash
./setup-symlinks.sh
```

## Troubleshooting

### Symlinks not working?
- **Windows**: Enable Developer Mode or run Git Bash as administrator
- **Linux/Mac**: Symlinks work out of the box

### Variables not recognized in IDE?
- Run `terraform init` in the environment folder
- Reload your IDE window

### Changes to base not affecting environments?
- Symlinks point to the actual file
- Changes are immediate (no need to "sync")
- Run `terraform plan` to see the changes

### Want to test changes without affecting all environments?
- Create a temporary copy (not symlink) in one environment
- Test your changes
- When satisfied, move changes to `_base/`
- Delete the temporary copy
