# Terraform Infrastructure Inheritance Pattern

**OOP-style inheritance for Terraform without third-party tools.**

Eliminate infrastructure duplication across environments using native Terraform + symlinks. Define your infrastructure once, inherit everywhere, with optional environment-specific additions.

## The Problem

Managing infrastructure across multiple environments (Dev, QA, Prod) typically means:
- Copying the same `.tf` files across 7+ folders
- Manual synchronization when updating modules
- Version drift between environments
- High maintenance burden

## The Solution

This pattern brings OOP-style inheritance to Terraform:
- **Base class** = `_base/` folder with shared infrastructure
- **Child classes** = environment folders (dev/, qa/, prod/)
- **Inheritance** = symlinks to base files
- **Extensions** = `{env}-*.tf` files for environment-specific additions

## What's Here

This repository contains a complete working example of **infrastructure inheritance** using symlinks to eliminate duplication across environments.

## Files

- **[PATTERN.md](PATTERN.md)** - Complete explanation of the pattern
- **[USAGE.md](USAGE.md)** - How to use: manual terraform vs GitHub Actions
- **[example-service/](example-service/)** - Working example with 3 environments (dev, qa, prod)
- **[.github/workflows/](.github/workflows/)** - Example GitHub Actions workflows

## Quick Start

### Option 1: Manual Terraform (Simplest)

```bash
cd example-service/dev

# Initialize and deploy
terraform init
terraform plan
terraform apply

# Edit base infrastructure
vim ../_base/main.tf  # Change applies to ALL environments

# Deploy to other environments
cd ../qa && terraform init && terraform apply
cd ../prod && terraform init && terraform apply
```

### Option 2: GitHub Actions (Automated)

```bash
# Edit base infrastructure
vim example-service/_base/main.tf
git add . && git commit -m "Update base infrastructure"
git push

# Base orchestrator workflow triggers dev → qa → prod automatically
```

See **[USAGE.md](USAGE.md)** for complete details on both approaches.

## The Pattern in One Picture

```
_base/
  └── main.tf              ← Define spot EC2 instance ONCE

dev/
  ├── main.tf → _base/     ← Symlink (inherits spot instance)
  └── dev-scaling.tf       ← Adds dev-specific log group

qa/
  ├── main.tf → _base/     ← Symlink (inherits spot instance)
  ├── qa-debug.tf          ← Adds QA debug resources
  └── qa-test-data.tf      ← Adds test data generators

prod/
  ├── main.tf → _base/     ← Symlink (inherits spot instance)
  ├── prod-backup.tf       ← Adds EBS volume + alarms
  ├── prod-monitoring.tf   ← Adds SNS alerts + CloudWatch
  └── prod-variables.tf    ← Adds prod-only variables
```

**Result:**
- All environments get the same spot EC2 instance (defined once in `_base/main.tf`)
- Each environment adds only what it needs
- Zero duplication, zero drift

## Key Features

✅ Define infrastructure once in `_base/`  
✅ Define variables once in `_base/variables.tf`  
✅ Environments symlink to base (automatic inheritance)  
✅ Add `{env}-*.tf` files per environment (optional resources/variables)  
✅ Environment files can use base variables (they're symlinked)  
✅ Environment-specific variables only defined where needed  
✅ IDE sees variables through symlinks (run `terraform init` first)  
✅ Each environment has unique workspace (backend.tf)  
✅ Workflow orchestration for base changes triggers all environments  
✅ Individual workflows for environment-specific changes  

## Why This Exists

You wanted OOP-style inheritance for Terraform:
- Base class = `_base/` folder
- Child classes = environment folders
- Inheritance = symlinks
- Extensions = `{env}-*.tf` files (resources + variables)

Terraform doesn't support this natively. This pattern uses symlinks to achieve it without third-party tools.

**Bonus:** Environment-specific variables can be defined only where needed. Prod needs `backup_retention_days`? Add `prod-variables.tf`. Other environments don't see it.

## Documentation

- **[README.md](README.md)** - This file, quick overview
- **[PATTERN.md](PATTERN.md)** - Complete technical documentation
- **[OVERVIEW.md](OVERVIEW.md)** - High-level summary and benefits
- **[example-service/](example-service/)** - Working example with 3 environments

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details

## Author

Created to solve real-world infrastructure duplication and drift problems at scale.

## Related Reading

- [Terraform Documentation](https://www.terraform.io/docs)
- [DRY Principle](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
- [Infrastructure as Code Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)
