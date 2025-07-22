# Outputs for VPC module

# VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnets
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = aws_db_subnet_group.main.name
}

# Security Groups
output "frontend_security_group_id" {
  description = "ID of the frontend security group"
  value       = aws_security_group.groups["frontend"].id
}

output "backend_security_group_id" {
  description = "ID of the backend security group"
  value       = aws_security_group.groups["backend"].id
}

output "postgres_security_group_id" {
  description = "ID of the postgres security group"
  value       = aws_security_group.groups["postgres"].id
}

output "pipeline_security_group_id" {
  description = "ID of the pipeline security group"
  value       = aws_security_group.groups["pipeline"].id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.groups["alb"].id
}

# Load Balancer
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.main[0].arn : null
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.main[0].dns_name : null
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.main[0].zone_id : null
}

# Target Groups
output "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  value       = lookup(aws_lb_target_group.main, "frontend", null) != null ? aws_lb_target_group.main["frontend"].arn : null
}

output "backend_target_group_arn" {
  description = "ARN of the backend target group"
  value       = lookup(aws_lb_target_group.main, "backend", null) != null ? aws_lb_target_group.main["backend"].arn : null
}

# EFS
output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = var.create_efs ? aws_efs_file_system.main[0].id : null
}

output "efs_file_system_arn" {
  description = "ARN of the EFS file system"
  value       = var.create_efs ? aws_efs_file_system.main[0].arn : null
}

# Secrets Manager
output "google_drive_credentials_secret_arn" {
  description = "ARN of the Google Drive credentials secret"
  value       = var.create_secrets && lookup(var.secrets, "google_drive_credentials", null) != null ? aws_secretsmanager_secret.main["google_drive_credentials"].arn : null
}

# NAT Gateways
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
} 