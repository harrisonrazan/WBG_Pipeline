# Variables for AWS Accounts Factory module

variable "create_organization" {
  description = "Whether to create a new AWS Organization"
  type        = bool
  default     = false
}

variable "accounts" {
  description = "Map of AWS accounts to create"
  type = map(object({
    name                       = string
    email                      = string
    role_name                  = string
    parent_id                  = string
    close_on_deletion          = bool
    create_govcloud           = bool
    iam_user_access_to_billing = string
    environment               = string
    tags                      = map(string)
  }))
  default = {}
}

variable "cross_account_roles" {
  description = "Cross-account roles to create"
  type = map(object({
    name                = string
    trusted_account_ids = list(string)
    external_id         = string
    policies            = list(string)
  }))
  default = {}
}

variable "audit_bucket_name" {
  description = "Name of the S3 bucket for audit logs"
  type        = string
  default     = ""
}

variable "allowed_regions" {
  description = "List of allowed AWS regions"
  type        = list(string)
  default     = ["us-east-1"]
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_billing_access" {
  description = "Whether to enable billing access for member accounts"
  type        = bool
  default     = true
}

# Organization structure
variable "organization_name" {
  description = "Name of the organization"
  type        = string
  default     = "luciowl"
}

variable "master_account_email" {
  description = "Email address for the master account"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "luciowl"
} 