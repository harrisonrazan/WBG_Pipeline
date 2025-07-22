# AWS Accounts Factory Module
# This module creates and manages AWS accounts using AWS Organizations

# Enable AWS Organizations (run this in master account)
resource "aws_organizations_organization" "main" {
  count = var.create_organization ? 1 : 0
  
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "account.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com"
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]

  feature_set = "ALL"

  # tags = merge(var.common_tags, {
  #   Name = "luciowl-organization"
  # })
}

# Organizational Units
resource "aws_organizations_organizational_unit" "core" {
  count     = var.create_organization ? 1 : 0
  name      = "Core"
  parent_id = aws_organizations_organization.main[0].roots[0].id

  tags = merge(var.common_tags, {
    Name = "Core-OU"
  })
}

resource "aws_organizations_organizational_unit" "dev" {
  count     = var.create_organization ? 1 : 0
  name      = "Development"
  parent_id = aws_organizations_organization.main[0].roots[0].id

  tags = merge(var.common_tags, {
    Name = "Development-OU"
  })
}

resource "aws_organizations_organizational_unit" "prod" {
  count     = var.create_organization ? 1 : 0
  name      = "Production"
  parent_id = aws_organizations_organization.main[0].roots[0].id

  tags = merge(var.common_tags, {
    Name = "Production-OU"
  })
}

# AWS Accounts
resource "aws_organizations_account" "accounts" {
  for_each = var.accounts

  name                       = each.value.name
  email                      = each.value.email
  role_name                  = each.value.role_name
  parent_id                  = each.value.parent_id
  close_on_deletion          = each.value.close_on_deletion
  create_govcloud           = each.value.create_govcloud
  iam_user_access_to_billing = each.value.iam_user_access_to_billing

  tags = merge(var.common_tags, each.value.tags, {
    Name = each.value.name
    Environment = each.value.environment
  })

  lifecycle {
    ignore_changes = [role_name]
  }
}

# Service Control Policies for different environments
resource "aws_organizations_policy" "cost_control_scp" {
  count = var.create_organization ? 1 : 0
  
  name        = "CostControlSCP"
  description = "Service Control Policy for Cost Management"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "organizations:*",
          "account:*"
        ]
        Resource = "*"
      },
      # Prevent expensive EC2 instances
      {
        Effect = "Deny"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringNotEquals = {
            "ec2:InstanceType" = [
              "t2.micro",
              "t2.small",
              "t3.micro",
              "t3.small",
              "t3.medium",
              "t4g.micro",
              "t4g.small"
            ]
          }
        }
      },
      # Prevent expensive RDS instances
      {
        Effect = "Deny"
        Action = [
          "rds:CreateDBInstance",
          "rds:CreateDBCluster"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "rds:db-instance-class" = [
              "db.t3.micro",
              "db.t3.small",
              "db.t4g.micro",
              "db.t4g.small"
            ]
          }
        }
      },
      # Restrict to allowed regions only
      {
        Effect = "Deny"
        Action = [
          "ec2:*",
          "rds:*",
          "lambda:*",
          "ecs:*",
          "eks:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      },
      # Prevent expensive services
      {
        Effect = "Deny"
        Action = [
          "sagemaker:*",
          "redshift:*",
          "emr:*",
          "elasticsearch:*",
          "opensearch:*",
          "kinesis:*",
          "databrew:*",
          "glue:*",
          "athena:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "CostControlSCP"
  })
}

resource "aws_organizations_policy" "dev_scp" {
  count = var.create_organization ? 1 : 0
  
  name        = "DevEnvironmentSCP"
  description = "Service Control Policy for Development Environment"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "organizations:*",
          "account:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "DevEnvironmentSCP"
  })
}

resource "aws_organizations_policy" "shared_scp" {
  count = var.create_organization ? 1 : 0
  
  name        = "SharedResourcesSCP"
  description = "Service Control Policy for Shared Resources Account"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "organizations:*",
          "account:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "SharedResourcesSCP"
  })
}

# Attach SCPs to accounts
# Cost control SCP on all accounts
resource "aws_organizations_policy_attachment" "cost_control_dev_network" {
  count = var.create_organization ? 1 : 0
  
  policy_id = aws_organizations_policy.cost_control_scp[0].id
  target_id = aws_organizations_account.accounts["dev-network"].id
}

resource "aws_organizations_policy_attachment" "cost_control_dev_workloads" {
  count = var.create_organization ? 1 : 0
  
  policy_id = aws_organizations_policy.cost_control_scp[0].id
  target_id = aws_organizations_account.accounts["dev-workloads"].id
}

resource "aws_organizations_policy_attachment" "cost_control_shared" {
  count = var.create_organization ? 1 : 0
  
  policy_id = aws_organizations_policy.cost_control_scp[0].id
  target_id = aws_organizations_account.accounts["shared"].id
}

resource "aws_organizations_policy_attachment" "dev_network_scp" {
  count = var.create_organization ? 1 : 0
  
  policy_id = aws_organizations_policy.dev_scp[0].id
  target_id = aws_organizations_account.accounts["dev-network"].id
}

resource "aws_organizations_policy_attachment" "dev_workloads_scp" {
  count = var.create_organization ? 1 : 0
  
  policy_id = aws_organizations_policy.dev_scp[0].id
  target_id = aws_organizations_account.accounts["dev-workloads"].id
}

resource "aws_organizations_policy_attachment" "shared_scp" {
  count = var.create_organization ? 1 : 0
  
  policy_id = aws_organizations_policy.shared_scp[0].id
  target_id = aws_organizations_account.accounts["shared"].id
}

# Cross-account IAM roles for access
resource "aws_iam_role" "cross_account_access" {
  for_each = var.cross_account_roles

  name = each.value.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = each.value.trusted_account_ids
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = each.value.external_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = each.value.name
  })
}

resource "aws_iam_role_policy_attachment" "cross_account_policies" {
  for_each = {
    for combo in flatten([
      for role_key, role in var.cross_account_roles : [
        for policy in role.policies : {
          key = "${role_key}-${policy}"
          role_name = aws_iam_role.cross_account_access[role_key].name
          policy_arn = policy
        }
      ]
    ]) : combo.key => combo
  }

  role       = each.value.role_name
  policy_arn = each.value.policy_arn
}

# CloudTrail for audit logging across accounts
resource "aws_cloudtrail" "organization_trail" {
  count = var.create_organization ? 1 : 0

  name                         = "luciowl-organization-trail"
  s3_bucket_name              = var.audit_bucket_name
  include_global_service_events = true
  is_multi_region_trail       = true
  is_organization_trail       = true

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${var.audit_bucket_name}/*"]
    }
  }

  tags = merge(var.common_tags, {
    Name = "Organization-CloudTrail"
  })
}

# Config for compliance monitoring
resource "aws_config_configuration_recorder" "organization_config" {
  count = var.create_organization ? 1 : 0

  name     = "luciowl-organization-config"
  role_arn = aws_iam_role.config_role[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_config_delivery_channel.organization_config]
}

resource "aws_config_delivery_channel" "organization_config" {
  count = var.create_organization ? 1 : 0

  name           = "luciowl-organization-config-delivery"
  s3_bucket_name = var.audit_bucket_name
}

resource "aws_iam_role" "config_role" {
  count = var.create_organization ? 1 : 0

  name = "luciowl-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "Config-ServiceRole"
  })
}

resource "aws_iam_role_policy_attachment" "config_role_policy" {
  count = var.create_organization ? 1 : 0

  role       = aws_iam_role.config_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
} 