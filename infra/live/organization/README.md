# AWS Accounts Factory

This directory contains the Terragrunt configuration to create and manage AWS accounts using AWS Organizations.

## 🏗️ What This Creates

The accounts factory will create:

1. **AWS Organization** with the following structure:
   ```
   Root Organization
   ├── Core OU
   │   └── Shared Account (ECR, S3, shared resources)
   └── Development OU
       ├── Dev-Network Account (VPC, ALB, networking)
       └── Dev-Workloads Account (ECS, RDS, applications)
   ```

2. **Service Control Policies (SCPs)** for security guardrails
3. **Cross-account IAM roles** for secure resource access
4. **Organization-wide CloudTrail** for audit logging
5. **AWS Config** for compliance monitoring

## 📋 Prerequisites

### 1. Email Addresses
You need **unique email addresses** for each account:
- Master account: `your-master-account@example.com`
- Shared account: `luciowl+shared@example.com`
- Dev-Network account: `luciowl+dev-network@example.com`
- Dev-Workloads account: `luciowl+dev-workloads@example.com`

### 2. AWS Permissions
Your AWS user/role must have:
- `OrganizationsFullAccess`
- `IAMFullAccess`
- `CloudTrailFullAccess`
- `ConfigServiceRolePolicy`

### 3. Terraform/Terragrunt
- Terraform >= 1.0
- Terragrunt >= 0.45

## 🚀 Deployment Steps

### Step 1: Update Email Addresses
Edit `infra/live/organization/accounts-factory/terragrunt.hcl` and update all email addresses:

```hcl
# Update this line
master_account_email = "your-actual-email@example.com"

# Update these in the accounts section
accounts = {
  shared = {
    email = "your-email+shared@example.com"
    # ... rest of config
  }
  # ... other accounts
}
```

### Step 2: Deploy the Organization
```bash
cd infra/live/organization/accounts-factory
terragrunt init
terragrunt plan
terragrunt apply
```

### Step 3: Verify Account Creation
```bash
# Check created accounts
aws organizations list-accounts

# Check organizational units
aws organizations list-organizational-units-for-parent --parent-id <root-id>
```

### Step 4: Set Up Cross-Account Access
After account creation, you'll need to:

1. **Assume roles in each account** to set up initial access
2. **Configure AWS profiles** for each account
3. **Update Terragrunt configurations** with actual account IDs

## 🔧 Configuration Details

### Account Structure
| Account | Purpose | OU | Email |
|---------|---------|----|----|
| **Shared** | ECR repositories, S3 buckets, shared resources | Core | luciowl+shared@example.com |
| **Dev-Network** | VPC, ALB, networking infrastructure | Development | luciowl+dev-network@example.com |
| **Dev-Workloads** | ECS services, RDS, applications | Development | luciowl+dev-workloads@example.com |

### Cross-Account Roles
- **SharedAccountAccess**: Allows dev accounts to read from ECR and S3
- **DevNetworkAccess**: Allows workloads account to read network resources

### Service Control Policies
- **Dev environments**: Restricted to specific regions, no organization access
- **Shared account**: Full access except organization management

## 🔐 Security Features

1. **Account Isolation**: Each account has its own AWS resources
2. **Service Control Policies**: Prevent unauthorized actions
3. **Cross-account roles**: Secure resource access between accounts
4. **CloudTrail**: Organization-wide audit logging
5. **Config**: Compliance monitoring and configuration tracking

## 📊 Cost Optimization

- **Single NAT Gateway** in dev environment
- **Regional restrictions** via SCPs
- **Lifecycle policies** for audit logs
- **Right-sized instances** for development

## 🔄 Next Steps

After accounts are created:

1. **Configure AWS profiles** for each account
2. **Deploy shared resources** (ECR, S3) to shared account
3. **Deploy networking** to dev-network account
4. **Deploy workloads** to dev-workloads account

## 📝 Important Notes

- **Email uniqueness**: Each account needs a unique email address
- **Account limits**: AWS has default limits on number of accounts
- **Billing**: Each account will have separate billing
- **Cross-account access**: Use IAM roles, not users
- **Organization master**: Keep master account secure and minimal

## 🆘 Troubleshooting

### Common Issues

1. **Email already in use**: Each AWS account needs a unique email
2. **Permission denied**: Ensure you have Organizations permissions
3. **Account creation failed**: Check email format and domain
4. **SCP conflicts**: Review service control policies

### Useful Commands

```bash
# List all accounts
aws organizations list-accounts

# Check organizational units
aws organizations list-organizational-units-for-parent --parent-id <root-id>

# Assume role in another account
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT-ID:role/OrganizationAccountAccessRole --role-session-name CrossAccountAccess
```

## 🔄 Clean Up

To destroy the accounts factory:

```bash
cd infra/live/organization/accounts-factory
terragrunt destroy
```

⚠️ **Warning**: This will close all created accounts. Ensure you want to permanently delete them. 