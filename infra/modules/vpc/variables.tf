# Variables for VPC module

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "database_subnets" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

# NAT Gateway Configuration
variable "enable_nat_gateway" {
  description = "Enable NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

# Load Balancer Configuration
variable "create_alb" {
  description = "Create Application Load Balancer"
  type        = bool
  default     = true
}

variable "alb_name" {
  description = "Name for the Application Load Balancer"
  type        = string
}

variable "target_groups" {
  description = "Target groups configuration for ALB"
  type = map(object({
    port               = number
    protocol           = string
    health_check_path  = string
    health_check_port  = number
  }))
  default = {}
}

variable "listener_rules" {
  description = "ALB listener rules configuration"
  type = list(object({
    priority = number
    actions = list(object({
      type             = string
      target_group_key = string
    }))
    conditions = list(object({
      path_pattern = list(string)
    }))
  }))
  default = []
}

# Security Groups Configuration
variable "security_groups" {
  description = "Security groups configuration"
  type = map(object({
    description = string
    ingress_rules = optional(list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks              = optional(list(string))
      source_security_group_id = optional(string)
    })), [])
    egress_rules = optional(list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string))
    })), [])
  }))
  default = {}
}

# EFS Configuration
variable "create_efs" {
  description = "Create EFS file system"
  type        = bool
  default     = false
}

variable "efs_name" {
  description = "Name for the EFS file system"
  type        = string
  default     = ""
}

# Secrets Manager Configuration
variable "create_secrets" {
  description = "Create secrets in AWS Secrets Manager"
  type        = bool
  default     = false
}

variable "secrets" {
  description = "Secrets to create in AWS Secrets Manager"
  type = map(object({
    description = string
  }))
  default = {}
} 