# Enable billing access for member accounts
resource "aws_organizations_organization" "billing_access" {
  count = var.enable_billing_access ? 1 : 0
  
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
}

# IAM policy for billing access
resource "aws_iam_policy" "billing_access_policy" {
  count = var.enable_billing_access ? 1 : 0
  
  name        = "BillingAccessPolicy"
  description = "Policy to allow billing access for member accounts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aws-portal:ViewBilling",
          "aws-portal:ViewAccount",
          "aws-portal:ViewPaymentMethods",
          "aws-portal:ViewUsage",
          "budgets:ViewBudget",
          "budgets:ViewBudgetAct*",
          "ce:GetCostAndUsage",
          "ce:GetUsageReport",
          "ce:GetMetrics",
          "ce:GetReservationCoverage",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetReservationUtilization",
          "ce:GetUtilizationMetrics",
          "ce:ListCostCategoryDefinitions",
          "ce:GetRightsizingRecommendation",
          "ce:GetSavingsPlansUtilization",
          "ce:GetSavingsPlansUtilizationDetails",
          "ce:GetSavingsPlansCoverage",
          "ce:GetSavingsPlansRecommendation",
          "ce:GetDimensionValues",
          "ce:GetUsageReport",
          "ce:GetCostCategories",
          "billing:GetBillingData",
          "billing:GetBillingDetails",
          "billing:GetBillingNotifications",
          "billing:GetBillingPreferences",
          "billing:GetContractInformation",
          "billing:GetCredits",
          "billing:GetIAMAccessPreference",
          "billing:GetSellerOfRecord",
          "billing:ListBillingViews",
          "cost-optimization-hub:GetPreferences",
          "cost-optimization-hub:GetRecommendation",
          "cost-optimization-hub:ListEnrollmentStatuses",
          "cost-optimization-hub:ListRecommendations",
          "cost-optimization-hub:ListRecommendationSummaries"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "BillingAccessPolicy"
    Purpose = "billing-access"
  })
}

# Attach billing policy to OrganizationAccountAccessRole in each member account
resource "aws_iam_role_policy_attachment" "billing_access_attachment" {
  for_each = var.enable_billing_access ? var.accounts : {}
  
  role       = "OrganizationAccountAccessRole"
  policy_arn = aws_iam_policy.billing_access_policy[0].arn
  
  # Note: This assumes the role exists in each member account
  depends_on = [aws_organizations_account.accounts]
} 