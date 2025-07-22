# Service Control Policy to restrict billing access to master account only
resource "aws_organizations_policy" "restrict_billing_access" {
  count = var.create_emergency_scp ? 1 : 0
  
  name        = "${var.project_name}-restrict-billing-access"
  description = "Deny billing access for member accounts, allow only for master account"
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
          # AWS Billing and Cost Management
          "aws-portal:*",
          "billing:*",
          "ce:*",
          "budgets:*",
          "cost-optimization-hub:*",
          "cur:*",
          "pricing:*",
          # Prevent viewing organization billing
          "organizations:DescribeBill*",
          "organizations:ListBill*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount": var.master_account_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-restrict-billing-access"
    Purpose = "billing-security"
  })
}

# Attach billing restriction SCP to member accounts only
resource "aws_organizations_policy_attachment" "restrict_billing_shared" {
  count = var.create_emergency_scp ? 1 : 0
  
  policy_id = aws_organizations_policy.restrict_billing_access[0].id
  target_id = var.shared_account_id
}

resource "aws_organizations_policy_attachment" "restrict_billing_dev_network" {
  count = var.create_emergency_scp ? 1 : 0
  
  policy_id = aws_organizations_policy.restrict_billing_access[0].id
  target_id = var.dev_network_account_id
}

resource "aws_organizations_policy_attachment" "restrict_billing_dev_workloads" {
  count = var.create_emergency_scp ? 1 : 0
  
  policy_id = aws_organizations_policy.restrict_billing_access[0].id
  target_id = var.dev_workloads_account_id
}

# NOTE: Master account (132502993834) is deliberately NOT included in attachments
# This allows the master account to retain full billing access while restricting member accounts 