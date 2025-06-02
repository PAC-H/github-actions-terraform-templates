# GitHub Actions Terraform Templates

A comprehensive set of GitHub Actions workflows and Terraform templates for Azure infrastructure deployment with OIDC authentication, automated testing, compliance scanning, and operational workflows.

## Features

- 🔐 **Azure OIDC Authentication** - Secure authentication without storing credentials
- 🚀 **Multi-Environment Support** - Staging and production environments with approval gates
- 📦 **Modular Architecture** - Reusable GitHub Actions and Terraform modules
- 🔍 **Compliance Scanning** - Azure Policy validation, TFLint, and Checkov security checks
- 🧪 **Infrastructure Testing** - Terratest integration for automated testing
- 📊 **Drift Detection** - Weekly automated drift detection
- 🔧 **Utility Operations** - State management, dependency graphs, targeted operations
- 📢 **Teams Notifications** - Integrated Microsoft Teams webhook notifications
- ⚡ **Performance Optimized** - Terraform provider caching and parallel execution

## Project Structure

```
/
├── .github/
│   ├── workflows/                 # GitHub Actions workflows
│   │   ├── terraform-main.yml           # Main deployment pipeline
│   │   ├── terraform-drift-detection.yml
│   │   ├── terraform-state-management.yml
│   │   ├── terraform-utilities.yml
│   │   ├── terraform-compliance.yml
│   │   └── terraform-testing.yml
│   └── actions/                   # Reusable GitHub Actions
│       ├── setup-terraform/
│       ├── azure-login/
│       ├── teams-notification/
│       └── terraform-cache/
├── config/                        # Environment configurations
│   ├── base.json                  # Shared configuration
│   ├── staging.json               # Staging-specific config
│   └── production.json            # Production-specific config
├── terraform/
│   ├── environments/              # Environment-specific deployments
│   │   ├── staging/
│   │   └── production/
│   └── modules/                   # Reusable Terraform modules
│       └── example/
├── tests/
│   ├── terratest/                 # Infrastructure tests
│   └── azure-policy/              # Compliance rules
└── README.md
```

## Quick Start

### 1. Prerequisites

- Azure subscription with appropriate permissions
- GitHub repository with Actions enabled
- Azure OIDC application registration configured
- Self-hosted GitHub Actions runners (optional but recommended)

### 2. Configuration

#### Azure OIDC Setup

1. Create an Azure AD application registration
2. Configure federated credentials for GitHub OIDC
3. Assign appropriate Azure RBAC roles to the service principal

#### Repository Configuration

1. Fill in the configuration files in the `config/` directory:

**config/base.json:**
```json
{
  "azure": {
    "tenant_id": "your-tenant-id",
    "subscription_id": "your-subscription-id", 
    "client_id": "your-client-id"
  },
  "notifications": {
    "teams_webhook": "your-teams-webhook-url"
  }
}
```

**config/staging.json & config/production.json:**
```json
{
  "terraform": {
    "backend": {
      "storage_account_name": "your-state-storage-account",
      "container_name": "your-state-container",
      "resource_group_name": "your-state-resource-group"
    }
  }
}
```

2. Set up GitHub Environment Protection Rules:
   - Go to Settings → Environments
   - Create `staging` and `production` environments
   - Configure required reviewers and deployment branches

### 3. Workflows Overview

#### Main Deployment (`terraform-main.yml`)
- **Triggers:** Push to develop/main, PRs to main, manual dispatch
- **Features:** Parallel validation, plan caching, approval gates
- **Flow:** Validation → Compliance → Staging → Production

#### Drift Detection (`terraform-drift-detection.yml`)
- **Schedule:** Weekly on Sundays
- **Purpose:** Detect infrastructure drift and generate reports

#### State Management (`terraform-state-management.yml`)
- **Operations:** Unlock, backup, restore state files
- **Schedule:** Weekly automated backups

#### Utilities (`terraform-utilities.yml`)
- **Operations:** tfupdate, dependency graphs, targeted apply/destroy
- **Triggers:** Manual dispatch, terraform file changes

#### Compliance (`terraform-compliance.yml`)
- **Tools:** TFLint, Checkov, Azure Policy validation
- **Triggers:** Pull requests, manual dispatch

#### Testing (`terraform-testing.yml`)
- **Framework:** Terratest with Go
- **Suites:** Basic, integration, or all tests

## Usage Examples

### Deploy to Staging
```bash
# Automatically triggers on push to develop branch
git push origin develop

# Or manually trigger
# Go to Actions → Terraform Main Deployment → Run workflow
```

### Run Drift Detection
```bash
# Manually trigger drift detection
# Go to Actions → Terraform Drift Detection → Run workflow
```

### Perform Targeted Operations
```bash
# Target specific resources for apply/destroy
# Go to Actions → Terraform Utilities → Run workflow
# Operation: target-apply
# Target resources: module.example.azurerm_resource_group.main
```

### Run Infrastructure Tests
```bash
# Run Terratest suite
# Go to Actions → Terraform Testing → Run workflow
# Test suite: basic
# Environment: staging
```

## Reusable Actions

### Setup Terraform
```yaml
- uses: ./.github/actions/setup-terraform
  with:
    terraform_version: latest
    working_directory: terraform/environments/staging
    environment: staging
```

### Azure Login
```yaml
- uses: ./.github/actions/azure-login
  with:
    tenant_id: ${{ secrets.AZURE_TENANT_ID }}
    subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    client_id: ${{ secrets.AZURE_CLIENT_ID }}
```

### Teams Notification
```yaml
- uses: ./.github/actions/teams-notification
  with:
    webhook_url: ${{ secrets.TEAMS_WEBHOOK }}
    status: success
    environment: production
    message: "Deployment completed successfully"
```

## Security Considerations

### RBAC Configuration
- **Staging Environment:** Contributor role on staging resource groups
- **Production Environment:** Custom role with minimal required permissions
- **State Storage:** Storage Blob Data Contributor role
- **Backup Storage:** Storage Blob Data Reader/Writer role

### GitHub Repository Settings
- Branch protection rules for main/develop branches
- Required status checks for all workflows
- Restrict push access to authorized users
- Enable signed commits (recommended)

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify OIDC configuration in Azure AD
   - Check federated credential subject claims
   - Ensure service principal has appropriate roles

2. **State Lock Issues**
   - Use the state management workflow to unlock
   - Verify Azure Storage permissions
   - Check for concurrent workflow runs

3. **Plan Cache Misses**
   - Terraform provider versions changed
   - Lock file modifications
   - Clear cache and re-run workflow

### Debugging

Enable debug logging by setting repository secrets:
- `ACTIONS_STEP_DEBUG=true`
- `ACTIONS_RUNNER_DEBUG=true`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with staging environment
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create GitHub Issues for bugs and feature requests
- Check the troubleshooting section
- Review workflow run logs for detailed error messages 