locals {
  # AWS Configuration - applies to all environments
  aws = {
    region = "us-east-1"
    profile = "personal"
  }
  
  # Project-wide settings
  project = {
    name = "luciowl"
    repository = "luciowl"
    managed_by = "terragrunt"
    environment = "organization"  # Default environment
  }
  
  # S3 Configuration for terraform state
  s3 = {
    terraform_state_bucket = "luciowl-terraform-state"
    terraform_locks_table = "luciowl-terraform-locks"
  }
  
  # Common tags that apply to all resources
  common_tags = {
    Project = "luciowl"
    ManagedBy = "terragrunt"
    Repository = "luciowl"
  }

  merged_config = {
    aws = local.aws
    project = local.project
    s3 = local.s3
    common_tags = local.common_tags
  }
} 