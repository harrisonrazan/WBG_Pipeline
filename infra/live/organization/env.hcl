locals {
  # Organization-specific configuration
  live_env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals

  organization = {
    master_account_email = "${local.live_env.project.name}-aws@gmail.com"
    master_account_id = "132502993834"  # Current master account ID
    create_organization = false
  }
  
  # AWS Accounts to Create
  accounts = {
    shared = {
      name = "${local.live_env.project.name}-dev-shared"
      email = "${local.live_env.project.name}-shared@gmail.com"
      environment = "shared"
      purpose = "Shared resources like ECR"
      cost_center = "Engineering"
    }
    
    dev-network = {
      name = "${local.live_env.project.name}-dev-network"
      email = "${local.live_env.project.name}-dev-network@gmail.com"
      environment = "dev"
      purpose = "Development network infrastructure"
      cost_center = "Engineering"
    }
    
    dev-workloads = {
      name = "${local.live_env.project.name}-dev-workloads"
      email = "${local.live_env.project.name}-dev-workloads@gmail.com"
      environment = "dev"
      purpose = "Development workloads and applications"
      cost_center = "Engineering"
    }
  }
  
  # Cross-Account Role Configuration
  cross_account_roles = {
    shared_access = {
      name = "SharedAccountAccess"
      external_id = "${local.live_env.project.name}-shared-access"
      policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
      ]
    }
    
    dev_network_access = {
      name = "DevNetworkAccess"
      external_id = "${local.live_env.project.name}-dev-network-access"
      policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonVPCReadOnlyAccess"
      ]
    }
  }
  
  # Audit logs configuration
  audit = {
    logs_bucket = "${local.live_env.project.name}-org-audit-logs"
  }
  
  # Organization-specific tags (to be merged with base tags)
  organization_tags = {
    Environment = "organization"
    Purpose = "organization-setup"
  }
} 