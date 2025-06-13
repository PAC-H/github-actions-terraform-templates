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
- 📥 **Import Operations** - Comprehensive resource import with safety measures
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
│   │   ├── terraform-utilities.yml      # Includes import operations
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
│   ├── production.json            # Production-specific config
│   └── imports/                   # Import configuration files
│       ├── staging-imports.json       # Bulk import config for staging
│       └── production-imports.json    # Bulk import config for production
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

#### GitHub Secrets Configuration

**Security Note:** Azure authentication credentials are managed via GitHub Secrets for enhanced security. Never store sensitive credentials in configuration files.

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add the following **Repository Secrets**:

```
AZURE_TENANT_ID          # Your Azure Tenant ID
AZURE_SUBSCRIPTION_ID    # Your Azure Subscription ID  
AZURE_CLIENT_ID          # Your Azure Client ID for OIDC
```

3. (Optional) Add the following secret for Teams notifications:
```
TEAMS_WEBHOOK_URL        # Your Microsoft Teams webhook URL
```

#### Repository Configuration

Fill in the configuration files in the `config/` directory:

**config/base.json:**
```json
{
  "terraform": {
    "version": "1.7.0",
    "providers": {
      "azurerm": {
        "version": "~> 3.0"
      }
    }
  },
  "notifications": {
    "teams_webhook": "REPLACE_WITH_YOUR_TEAMS_WEBHOOK_URL"
  },
  "storage": {
    "backup_account": "REPLACE_WITH_BACKUP_STORAGE_ACCOUNT",
    "backup_container": "terraform-state-backups"
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
      "resource_group_name": "your-state-resource-group",
      "key": "terraform.tfstate"
    }
  },
  "deployment": {
    "auto_approve": false,
    "notification_enabled": true
  }
}
```

#### GitHub Environment Protection

Set up GitHub Environment Protection Rules for approval gates:
   - Go to Settings → Environments
   - Create `staging` and `production` environments
   - Configure required reviewers and deployment branches
   - Set environment-specific secrets if needed

### 3. Workflows Overview

#### Main Deployment (`terraform-main.yml`)
- **Triggers:** Push to develop/main, PRs to main, manual dispatch
- **Features:** Parallel validation, plan caching, approval gates
- **Flow:** Validation → Compliance → Staging → Production

#### Drift Detection (`terraform-drift-detection.yml`)
- **Schedule:** Weekly on Sundays at 9 AM UTC
- **Purpose:** Detect infrastructure drift and generate reports

#### State Management (`terraform-state-management.yml`)
- **Operations:** Unlock, backup, restore state files
- **Schedule:** Weekly automated backups on Sundays at 2 AM UTC

#### Utilities (`terraform-utilities.yml`)
- **Operations:** tfupdate, dependency graphs, targeted apply/destroy, import operations
- **Import Types:** Individual resource import, bulk import, dry-run validation
- **Safety Features:** State backup, validation, approval gates
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

### Import Existing Resources
```bash
# Import individual resource
# Go to Actions → Terraform Utilities → Run workflow
# Operation: import-individual
# Environment: staging
# Resource Address: azurerm_resource_group.main
# Resource ID: /subscriptions/12345.../resourceGroups/my-rg

# Import multiple resources from config file
# Go to Actions → Terraform Utilities → Run workflow
# Operation: import-bulk
# Environment: staging
# Import Config File: config/imports/staging-imports.json

# Dry-run to validate imports before execution
# Go to Actions → Terraform Utilities → Run workflow
# Operation: import-dry-run
# Environment: staging
# (specify individual or bulk import parameters)
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
    terraform_version: 1.7.0
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
    webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
    status: success
    environment: production
    message: "Deployment completed successfully"
```

## Security Considerations

### Authentication & Authorization
- **Azure OIDC:** All authentication uses OIDC tokens - no stored credentials
- **GitHub Secrets:** Sensitive data encrypted and managed by GitHub
- **Principle of Least Privilege:** Service principals have minimal required permissions

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
- Environment protection rules with manual approvals

### Secret Management Best Practices
- Use GitHub repository secrets for sensitive data
- Rotate credentials regularly
- Audit secret access and usage
- Use environment-specific secrets when needed

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify GitHub Secrets are correctly set: `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`
   - Check OIDC configuration in Azure AD
   - Verify federated credential subject claims
   - Ensure service principal has appropriate roles

2. **State Lock Issues**
   - Use the state management workflow to unlock
   - Verify Azure Storage permissions
   - Check for concurrent workflow runs

3. **Plan Cache Misses**
   - Terraform provider versions changed
   - Lock file modifications
   - Clear cache and re-run workflow

4. **Secret Access Issues**
   - Verify secrets are defined at repository level
   - Check if environment-specific secrets are needed
   - Ensure proper secret naming (case-sensitive)

### Debugging

Enable debug logging by setting repository secrets:
- `ACTIONS_STEP_DEBUG=true`
- `ACTIONS_RUNNER_DEBUG=true`

### Validation Steps

Before running workflows, verify:
1. All required GitHub Secrets are configured
2. Azure OIDC federated credentials are properly set up
3. Service principal has necessary Azure RBAC roles
4. GitHub environments are configured with protection rules
5. Configuration files contain valid values (no placeholder text)

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

## Import Operations

### Overview

The import functionality allows you to bring existing Azure resources under Terraform management with comprehensive safety measures:

- **Individual Imports:** Import single resources via workflow inputs
- **Bulk Imports:** Import multiple resources from configuration files
- **Dry-Run Mode:** Validate imports before execution
- **State Backup:** Automatic backup before any import operation
- **Verification:** State integrity checks after import
- **Approval Gates:** Production imports require manual approval

### Import Configuration

#### Individual Import

For single resource imports, provide:
- **Resource Address:** Terraform resource identifier (e.g., `azurerm_resource_group.main`)
- **Resource ID:** Full Azure resource ID (e.g., `/subscriptions/.../resourceGroups/my-rg`)

#### Bulk Import Configuration

Create import configuration files in `config/imports/`:

**config/imports/staging-imports.json:**
```json
{
  "description": "Bulk import configuration for staging environment",
  "environment": "staging",
  "imports": [
    {
      "resource_address": "azurerm_resource_group.main",
      "resource_id": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-staging-example",
      "description": "Main resource group for staging environment"
    },
    {
      "resource_address": "azurerm_storage_account.state",
      "resource_id": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-staging-tfstate/providers/Microsoft.Storage/storageAccounts/stagingstatestg",
      "description": "Terraform state storage account"
    }
  ]
}
```

### Import Workflow Operations

#### 1. import-individual
Import a single Azure resource into Terraform state:
- **Required Inputs:** `import_resource_address`, `import_resource_id`
- **Safety:** Automatic state backup, validation, verification
- **Approval:** Required for production environment

#### 2. import-bulk
Import multiple resources from a configuration file:
- **Required Input:** `import_config_file`
- **Features:** Batch processing, skip existing resources, progress tracking
- **Safety:** Comprehensive validation, state backup, failure handling

#### 3. import-dry-run
Validate import operations without making changes:
- **Purpose:** Test import configuration, verify resource existence
- **Output:** Detailed validation report, import readiness assessment
- **Safety:** No state modifications, read-only validation

### Import Safety Features

#### State Backup
- **Automatic:** Created before any import operation (except dry-run)
- **Retention:** 90 days for recovery purposes
- **Format:** Timestamped state files
- **Storage:** GitHub Actions artifacts

#### Validation
- **Resource Existence:** Verify Azure resources exist and are accessible
- **State Conflicts:** Check if resources already exist in Terraform state
- **Configuration:** Validate JSON format and required fields
- **Permissions:** Ensure proper Azure RBAC permissions

#### Verification
- **Post-Import:** State integrity checks after import
- **Configuration Drift:** Detect any required configuration updates
- **Plan Generation:** Create plan showing necessary changes
- **Reporting:** Comprehensive import operation reports

### Usage Examples

#### Import Individual Resource
```bash
# Manual workflow dispatch
1. Go to Actions → Terraform Utilities
2. Click "Run workflow"
3. Select:
   - Operation: import-individual
   - Environment: staging
   - Resource Address: azurerm_resource_group.main
   - Resource ID: /subscriptions/12345.../resourceGroups/my-rg
4. Click "Run workflow"
```

#### Import Bulk Resources
```bash
# Manual workflow dispatch
1. Create/update config/imports/staging-imports.json
2. Go to Actions → Terraform Utilities
3. Click "Run workflow"
4. Select:
   - Operation: import-bulk
   - Environment: staging
   - Import Config File: config/imports/staging-imports.json
5. Click "Run workflow"
```

#### Validate Import (Dry-Run)
```bash
# Test before actual import
1. Go to Actions → Terraform Utilities
2. Click "Run workflow"
3. Select:
   - Operation: import-dry-run
   - Environment: staging
   - (provide individual or bulk import parameters)
4. Review validation report in artifacts
```

### Getting Azure Resource IDs

Find Azure resource IDs using:

#### Azure Portal
1. Navigate to your resource
2. Go to Properties
3. Copy the "Resource ID" field

#### Azure CLI
```bash
# Resource Group
az group show --name "my-resource-group" --query id --output tsv

# Storage Account
az storage account show --name "mystorageaccount" --resource-group "my-rg" --query id --output tsv

# Virtual Network
az network vnet show --name "my-vnet" --resource-group "my-rg" --query id --output tsv
```

#### PowerShell
```powershell
# Resource Group
(Get-AzResourceGroup -Name "my-resource-group").ResourceId

# Storage Account
(Get-AzStorageAccount -ResourceGroupName "my-rg" -Name "mystorageaccount").Id
```

### Best Practices

#### Before Import
1. **Backup State:** Always ensured automatically by the workflow
2. **Dry-Run First:** Use import-dry-run to validate before actual import
3. **Resource Mapping:** Ensure Terraform resource addresses match your configuration
4. **Permissions:** Verify Azure RBAC permissions for resource access

#### During Import
1. **Monitor Logs:** Watch workflow execution for any issues
2. **Review Reports:** Check validation and operation reports
3. **Handle Failures:** Address any failed imports individually

#### After Import
1. **Review Drift:** Check post-import plan for required configuration updates
2. **Update Configuration:** Modify Terraform files to match imported resource settings
3. **Test Changes:** Run terraform plan to ensure configuration alignment
4. **Documentation:** Update documentation with imported resources

### Troubleshooting Import Issues

#### Common Issues

1. **Resource Already in State**
   - **Error:** Resource already exists in Terraform state
   - **Solution:** Use terraform state list to check existing resources
   - **Prevention:** Run dry-run validation first

2. **Resource Not Found**
   - **Error:** Azure resource not found or not accessible
   - **Solution:** Verify resource ID and Azure permissions
   - **Check:** Ensure resource exists and is in correct subscription

3. **Permission Denied**
   - **Error:** Insufficient permissions to access resource
   - **Solution:** Verify service principal has appropriate RBAC roles
   - **Required:** At minimum Reader role on resources to import

4. **Invalid Resource Address**
   - **Error:** Terraform resource address doesn't match configuration
   - **Solution:** Ensure resource address matches your .tf files exactly
   - **Check:** Verify module paths and resource naming

#### Recovery Procedures

If import operations fail:

1. **State Recovery:** Download state backup from workflow artifacts
2. **Manual Restoration:** Use state management workflow to restore if needed
3. **Retry Import:** Fix issues and retry import operation
4. **Support:** Review workflow logs and create GitHub issue if needed 