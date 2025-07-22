# Outputs for AWS Accounts Factory module

output "organization_id" {
  description = "The ID of the AWS organization"
  value       = var.create_organization ? aws_organizations_organization.main[0].id : null
}

output "organization_arn" {
  description = "The ARN of the AWS organization"
  value       = var.create_organization ? aws_organizations_organization.main[0].arn : null
}

output "organization_master_account_id" {
  description = "The ID of the master account"
  value       = var.create_organization ? aws_organizations_organization.main[0].master_account_id : null
}

output "organization_master_account_email" {
  description = "The email address of the master account"
  value       = var.create_organization ? aws_organizations_organization.main[0].master_account_email : null
}

# Organizational Units
output "core_ou_id" {
  description = "The ID of the Core organizational unit"
  value       = var.create_organization ? aws_organizations_organizational_unit.core[0].id : null
}

output "dev_ou_id" {
  description = "The ID of the Development organizational unit"
  value       = var.create_organization ? aws_organizations_organizational_unit.dev[0].id : null
}

output "prod_ou_id" {
  description = "The ID of the Production organizational unit"
  value       = var.create_organization ? aws_organizations_organizational_unit.prod[0].id : null
}

# Account details
output "account_ids" {
  description = "Map of account names to their IDs"
  value = {
    for name, account in aws_organizations_account.accounts : name => account.id
  }
}

output "account_emails" {
  description = "Map of account names to their email addresses"
  value = {
    for name, account in aws_organizations_account.accounts : name => account.email
  }
}

output "account_arns" {
  description = "Map of account names to their ARNs"
  value = {
    for name, account in aws_organizations_account.accounts : name => account.arn
  }
}

# Specific account outputs for easy reference
output "shared_account_id" {
  description = "The ID of the shared account"
  value       = lookup(aws_organizations_account.accounts, "shared", null) != null ? aws_organizations_account.accounts["shared"].id : null
}

output "dev_network_account_id" {
  description = "The ID of the dev-network account"
  value       = lookup(aws_organizations_account.accounts, "dev-network", null) != null ? aws_organizations_account.accounts["dev-network"].id : null
}

output "dev_workloads_account_id" {
  description = "The ID of the dev-workloads account"
  value       = lookup(aws_organizations_account.accounts, "dev-workloads", null) != null ? aws_organizations_account.accounts["dev-workloads"].id : null
}

# Cross-account role ARNs
output "cross_account_role_arns" {
  description = "Map of cross-account role names to their ARNs"
  value = {
    for name, role in aws_iam_role.cross_account_access : name => role.arn
  }
}

# Service Control Policy IDs
output "dev_scp_id" {
  description = "The ID of the development environment SCP"
  value       = var.create_organization ? aws_organizations_policy.dev_scp[0].id : null
}

output "shared_scp_id" {
  description = "The ID of the shared resources SCP"
  value       = var.create_organization ? aws_organizations_policy.shared_scp[0].id : null
}

# CloudTrail
output "organization_trail_arn" {
  description = "The ARN of the organization CloudTrail"
  value       = var.create_organization ? aws_cloudtrail.organization_trail[0].arn : null
}

# Config
output "config_recorder_name" {
  description = "The name of the Config recorder"
  value       = var.create_organization ? aws_config_configuration_recorder.organization_config[0].name : null
}

output "config_delivery_channel_name" {
  description = "The name of the Config delivery channel"
  value       = var.create_organization ? aws_config_delivery_channel.organization_config[0].name : null
} 