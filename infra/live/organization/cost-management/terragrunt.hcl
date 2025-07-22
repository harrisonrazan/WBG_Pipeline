terraform {
  source = "../../../modules//cost-management"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Dependency on accounts-factory to get account IDs
dependency "accounts_factory" {
  config_path = "../accounts-factory"
  mock_outputs = {
    account_ids = {
      dev-network   = "000000000000"
      dev-workloads = "000000000000"
      shared        = "000000000000"
    }
  }
}

locals {
  # Get organization configuration
  org_env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  live_env = local.org_env.live_env
}

inputs = {
  project_name                     = local.org_env.live_env.project.name
  monthly_budget_limit            = 150
  individual_account_budget_limit = 50
  notification_email              = "harrisonrazan+aws@gmail.com"
  organization_id                 = local.org_env.organization.master_account_id
  
  # Account IDs for monitoring
  account_ids = [
    local.org_env.organization.master_account_id,
    dependency.accounts_factory.outputs.account_ids["shared"],
    dependency.accounts_factory.outputs.account_ids["dev-network"],
    dependency.accounts_factory.outputs.account_ids["dev-workloads"]
  ]
  
  # Individual account IDs for billing restriction SCP
  master_account_id       = local.org_env.organization.master_account_id
  shared_account_id       = dependency.accounts_factory.outputs.account_ids["shared"]
  dev_network_account_id  = dependency.accounts_factory.outputs.account_ids["dev-network"]
  dev_workloads_account_id = dependency.accounts_factory.outputs.account_ids["dev-workloads"]
  
  # Enable kill switch features
  create_emergency_scp = true
  
  alert_thresholds = {
    actual_25_percent     = 25
    actual_50_percent     = 50
    actual_75_percent     = 75
    forecasted_90_percent = 90
    forecasted_100_percent = 100
  }
  
  # Properly merge base common_tags with cost-management specific tags
  common_tags = merge(local.org_env.live_env.common_tags, {
    Environment = "organization"
    Purpose = "cost-management"
    Component = "budgets"
  })
} 