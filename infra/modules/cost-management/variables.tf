variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 150
}

variable "notification_email" {
  description = "Email address for budget notifications"
  type        = string
}

variable "account_ids" {
  description = "List of AWS account IDs to monitor"
  type        = list(string)
}

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
  default     = ""
}

variable "master_account_id" {
  description = "Master/Management AWS account ID"
  type        = string
}

variable "shared_account_id" {
  description = "Shared AWS account ID"
  type        = string
}

variable "dev_network_account_id" {
  description = "Dev Network AWS account ID"
  type        = string
}

variable "dev_workloads_account_id" {
  description = "Dev Workloads AWS account ID"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "alert_thresholds" {
  description = "Budget alert thresholds"
  type = object({
    actual_25_percent     = number
    actual_50_percent     = number
    actual_75_percent     = number
    forecasted_90_percent = number
    forecasted_100_percent = number
  })
  default = {
    actual_25_percent     = 25
    actual_50_percent     = 50
    actual_75_percent     = 75
    forecasted_90_percent = 90
    forecasted_100_percent = 100
  }
}

variable "individual_account_budget_limit" {
  description = "Individual account budget limit in USD"
  type        = number
  default     = 50
}

variable "create_emergency_scp" {
  description = "Whether to create emergency cost control Service Control Policy"
  type        = bool
  default     = true
} 