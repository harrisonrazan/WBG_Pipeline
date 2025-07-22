locals {
  # Get environment configuration
  org_env = read_terragrunt_config("../env.hcl").locals
  live_env = local.org_env.live_env
  
  aws_region = local.live_env.aws.region
  aws_profile = local.live_env.aws.profile
  
  # Hardcoded common tags
  common_tags = {
    Project = local.live_env.project.name
    Environment = local.live_env.project.environment
    ManagedBy = local.live_env.project.managed_by
    Purpose = "organization-setup"
  }
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "${local.live_env.s3.terraform_state_bucket}-${local.aws_region}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = local.live_env.s3.terraform_locks_table
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"
  profile = "${local.aws_profile}"
  
  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}
EOF
}

# Input variables that will be available to all organization modules
inputs = {
  aws_region = local.aws_region
  common_tags = local.common_tags
  project_name = local.live_env.project.name
  
  # Pass the environment configuration for modules to use
  env = local.org_env
}
