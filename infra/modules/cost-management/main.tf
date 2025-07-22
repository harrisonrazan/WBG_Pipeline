# Organization-wide monthly budget
resource "aws_budgets_budget" "organization_monthly" {
  name         = "${var.project_name}-organization-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2025-01-01_00:00"
  
  cost_filter {
    name   = "LinkedAccount"
    values = var.account_ids
  }
  
  # 25% threshold - Early warning
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = var.alert_thresholds.actual_25_percent
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }
  
  # 50% threshold - Moderate concern
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = var.alert_thresholds.actual_50_percent
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }
  
  # 75% threshold - High concern
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = var.alert_thresholds.actual_75_percent
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }
  
  # 90% forecasted threshold - Critical warning
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = var.alert_thresholds.forecasted_90_percent
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.notification_email]
  }
  
  # 100% forecasted threshold - Emergency alert
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = var.alert_thresholds.forecasted_100_percent
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.notification_email]
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-organization-budget"
    Purpose = "cost-monitoring"
  })
}

# Emergency Cost Control SCP (Applied when budget is exceeded)
resource "aws_organizations_policy" "emergency_cost_control" {
  count = var.create_emergency_scp ? 1 : 0
  
  name        = "${var.project_name}-emergency-cost-control"
  description = "Emergency SCP to lock down all resource creation when budget is exceeded"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Allow essential read-only operations
          "sts:GetCallerIdentity",
          "sts:GetSessionToken",
          "sts:AssumeRole",
          # Allow budget/billing operations
          "budgets:*",
          "billing:*",
          "cost-optimization-hub:*",
          "ce:*",
          # Allow CloudWatch for monitoring
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "cloudwatch:Describe*",
          # Allow logging
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:Describe*",
          "logs:Get*"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          # Block all resource creation/modification
          "ec2:RunInstances",
          "ec2:StartInstances",
          "rds:CreateDBInstance",
          "rds:CreateDBCluster",
          "lambda:CreateFunction",
          "ecs:CreateCluster",
          "ecs:CreateService",
          "eks:CreateCluster",
          "elasticloadbalancing:CreateLoadBalancer",
          "s3:CreateBucket",
          "dynamodb:CreateTable",
          # Block scaling operations
          "autoscaling:*",
          "application-autoscaling:*",
          # Block expensive services
          "sagemaker:*",
          "redshift:*",
          "emr:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalArn": [
              "arn:aws:iam::*:role/*budget*",
              "arn:aws:iam::*:role/*terraform*",
              "arn:aws:iam::*:role/*admin*"
            ]
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-emergency-cost-control"
    Purpose = "emergency-cost-lockdown"
  })
}

# Individual account budgets as safety nets
resource "aws_budgets_budget" "individual_account_budgets" {
  for_each = toset(var.account_ids)
  
  name         = "${var.project_name}-account-${each.value}-budget"
  budget_type  = "COST"
  limit_amount = var.individual_account_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2025-01-01_00:00"
  
  cost_filter {
    name   = "LinkedAccount"
    values = [each.value]
  }
  
  # 80% threshold for individual accounts
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }
  
  # 100% forecasted threshold for individual accounts
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.notification_email]
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-account-${each.value}-budget"
    Purpose = "cost-monitoring"
    Account = each.value
  })
}

# Note: AWS Budget Actions are complex and require specific provider versions
# The Lambda-based kill switch provides more flexibility and reliability
# Manual SCP application instructions:
# 1. When you hit 80% budget, manually apply the emergency SCP using:
#    aws organizations attach-policy --policy-id <policy-id> --target-id <account-id>
# 2. To remove the lockdown:
#    aws organizations detach-policy --policy-id <policy-id> --target-id <account-id>