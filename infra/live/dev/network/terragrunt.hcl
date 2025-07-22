terraform {
  source = "../../../modules/vpc"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  environment = "dev"
  
  # VPC Configuration
  vpc_cidr = "10.0.0.0/16"
  azs = ["us-east-1a", "us-east-1b"]
  
  # Subnet configuration
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]
  
  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization for dev
  
  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support = true
  
  # Load Balancer configuration
  create_alb = true
  alb_name = "luciowl-dev-alb"
  
  # Target groups for services
  target_groups = {
    frontend = {
      port = 3000
      protocol = "HTTP"
      health_check_path = "/"
      health_check_port = 3000
    }
    backend = {
      port = 8000
      protocol = "HTTP"
      health_check_path = "/health"
      health_check_port = 8000
    }
  }
  
  # ALB listener rules
  listener_rules = [
    {
      priority = 100
      actions = [{
        type = "forward"
        target_group_key = "frontend"
      }]
      conditions = [{
        path_pattern = ["/*"]
      }]
    },
    {
      priority = 200
      actions = [{
        type = "forward"
        target_group_key = "backend"
      }]
      conditions = [{
        path_pattern = ["/api/*", "/health", "/docs"]
      }]
    }
  ]
  
  # Security Groups
  security_groups = {
    frontend = {
      description = "Security group for frontend service"
      ingress_rules = [
        {
          from_port = 3000
          to_port = 3000
          protocol = "tcp"
          source_security_group_id = "alb"
        }
      ]
      egress_rules = [
        {
          from_port = 0
          to_port = 65535
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    backend = {
      description = "Security group for backend service"
      ingress_rules = [
        {
          from_port = 8000
          to_port = 8000
          protocol = "tcp"
          source_security_group_id = "alb"
        },
        {
          from_port = 8000
          to_port = 8000
          protocol = "tcp"
          source_security_group_id = "frontend"
        }
      ]
      egress_rules = [
        {
          from_port = 0
          to_port = 65535
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    postgres = {
      description = "Security group for PostgreSQL database"
      ingress_rules = [
        {
          from_port = 5432
          to_port = 5432
          protocol = "tcp"
          source_security_group_id = "backend"
        },
        {
          from_port = 5432
          to_port = 5432
          protocol = "tcp"
          source_security_group_id = "pipeline"
        }
      ]
    }
    pipeline = {
      description = "Security group for pipeline service"
      egress_rules = [
        {
          from_port = 0
          to_port = 65535
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    alb = {
      description = "Security group for Application Load Balancer"
      ingress_rules = [
        {
          from_port = 80
          to_port = 80
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          from_port = 443
          to_port = 443
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      egress_rules = [
        {
          from_port = 0
          to_port = 65535
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
  }
  
  # EFS for shared volumes (queries directory)
  create_efs = true
  efs_name = "luciowl-dev-queries"
  
  # AWS Secrets Manager for sensitive data
  create_secrets = true
  secrets = {
    google_drive_credentials = {
      description = "Google Drive service account credentials"
    }
  }
  
  tags = {
    Environment = "dev"
    Project = "luciowl"
  }
} 