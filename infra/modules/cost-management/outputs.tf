output "organization_budget_name" {
  description = "Name of the organization-wide budget"
  value       = aws_budgets_budget.organization_monthly.name
}

output "organization_budget_arn" {
  description = "ARN of the organization-wide budget"
  value       = aws_budgets_budget.organization_monthly.arn
}

output "individual_account_budget_names" {
  description = "Names of individual account budgets"
  value       = { for k, v in aws_budgets_budget.individual_account_budgets : k => v.name }
}

output "individual_account_budget_arns" {
  description = "ARNs of individual account budgets"
  value       = { for k, v in aws_budgets_budget.individual_account_budgets : k => v.arn }
}

# Note: Anomaly detection outputs removed due to AWS provider compatibility
# You can manually set up cost anomaly detection in the AWS Console

output "budget_summary" {
  description = "Summary of budget configuration"
  value = {
    organization_budget_limit = var.monthly_budget_limit
    individual_account_limit  = var.individual_account_budget_limit
    notification_email        = var.notification_email
    monitored_accounts        = var.account_ids
    alert_thresholds         = var.alert_thresholds
  }
} 