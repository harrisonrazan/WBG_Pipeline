terraform {
  source = "../../../modules//aws-accounts?ref=main"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  # Merge base and organization configurations
  org_env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  live_env = local.org_env.live_env
  
  # Create merged environment configuration
  env = {
    # Base configuration
    aws = local.live_env.aws
    project = local.live_env.project
    s3 = local.live_env.s3
    
    # Organization-specific configuration
    organization = local.org_env.organization
    accounts = local.org_env.accounts
    cross_account_roles = local.org_env.cross_account_roles
    audit = local.org_env.audit
    
    # Merged common tags
    common_tags = merge(local.live_env.common_tags, local.org_env.organization_tags)
  }
  
  # Account Factory specific values
  core_ou_id = null  # Set this to your core OU ID once organization is created
  dev_ou_id = null   # Set this to your dev OU ID once organization is created
  
  # Account IDs for cross-account role setup
  dev_network_account_id = "941098798605"
  dev_workloads_account_id = "268456953580"
  dev_shared_account_id = "268456953580"
}

inputs = {
  create_organization = local.org_env.organization.create_organization
  
  # Enable billing access for member accounts
  enable_billing_access = true
  
  # Audit bucket for CloudTrail and Config (using timestamp for uniqueness)
  audit_bucket_name = "${local.org_env.audit.logs_bucket}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # Master account email
  master_account_email = local.org_env.organization.master_account_email
  
  # AWS accounts to create
  accounts = {
    shared = {
      name                       = local.org_env.accounts.shared.name
      email                      = local.org_env.accounts.shared.email
      role_name                  = "OrganizationAccountAccessRole"
      parent_id                  = local.core_ou_id
      close_on_deletion          = true
      create_govcloud           = false
      iam_user_access_to_billing = "ALLOW"
      environment               = local.org_env.accounts.shared.environment
      tags = {
        Purpose = local.org_env.accounts.shared.purpose
        CostCenter = local.org_env.accounts.shared.cost_center
      }
    }
    
    dev-network = {
      name                       = local.org_env.accounts.dev-network.name
      email                      = local.org_env.accounts.dev-network.email
      role_name                  = "OrganizationAccountAccessRole"
      parent_id                  = local.dev_ou_id
      close_on_deletion          = true
      create_govcloud           = false
      iam_user_access_to_billing = "ALLOW"
      environment               = local.org_env.accounts.dev-network.environment
      tags = {
        Purpose = local.org_env.accounts.dev-network.purpose
        CostCenter = local.org_env.accounts.dev-network.cost_center
      }
    }
    
    dev-workloads = {
      name                       = local.org_env.accounts.dev-workloads.name
      email                      = local.org_env.accounts.dev-workloads.email
      role_name                  = "OrganizationAccountAccessRole"
      parent_id                  = local.dev_ou_id
      close_on_deletion          = true
      create_govcloud           = false
      iam_user_access_to_billing = "ALLOW"
      environment               = local.org_env.accounts.dev-workloads.environment
      tags = {
        Purpose = local.org_env.accounts.dev-workloads.purpose
        CostCenter = local.org_env.accounts.dev-workloads.cost_center
      }
    }
  }
  
  # Cross-account roles for accessing resources
  cross_account_roles = {
    shared-access = {
      name                = local.org_env.cross_account_roles.shared_access.name
      trusted_account_ids = [
        local.dev_network_account_id,
        local.dev_workloads_account_id
      ]
      external_id = local.org_env.cross_account_roles.shared_access.external_id
      policies = local.org_env.cross_account_roles.shared_access.policies
    }
    
    dev-network-access = {
      name                = local.org_env.cross_account_roles.dev_network_access.name
      trusted_account_ids = [
        local.dev_workloads_account_id
      ]
      external_id = local.org_env.cross_account_roles.dev_network_access.external_id
      policies = local.org_env.cross_account_roles.dev_network_access.policies
    }
  }
  
  # Allowed regions for cost optimization
  allowed_regions = [local.live_env.aws.region]
  
  tags = merge(local.live_env.common_tags, {
    Purpose = "account-factory"
    Component = "accounts-factory"
  })
} 