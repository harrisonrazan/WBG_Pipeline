# VPC Module for Stack Sandbox
# This module creates the core networking infrastructure including VPC, subnets, security groups, ALB, and EFS

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-${var.azs[count.index]}"
    Type = "public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-${var.azs[count.index]}"
    Type = "private"
  })
}

# Database Subnets
resource "aws_subnet" "database" {
  count = length(var.database_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-database-${var.azs[count.index]}"
    Type = "database"
  })
}

# Database Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.single_nat_gateway ? 1 : length(var.public_subnets)

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : length(var.private_subnets)

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

# Security Groups
resource "aws_security_group" "groups" {
  for_each = var.security_groups

  name_prefix = "${var.name_prefix}-${each.key}-"
  description = each.value.description
  vpc_id      = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${each.key}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Rules
resource "aws_security_group_rule" "ingress" {
  for_each = {
    for rule in flatten([
      for sg_name, sg in var.security_groups : [
        for i, rule in lookup(sg, "ingress_rules", []) : {
          key                      = "${sg_name}-ingress-${i}"
          security_group_id        = aws_security_group.groups[sg_name].id
          type                     = "ingress"
          from_port                = rule.from_port
          to_port                  = rule.to_port
          protocol                 = rule.protocol
          cidr_blocks              = lookup(rule, "cidr_blocks", null)
          source_security_group_id = lookup(rule, "source_security_group_id", null) == "alb" ? aws_security_group.groups["alb"].id : (lookup(rule, "source_security_group_id", null) != null ? aws_security_group.groups[rule.source_security_group_id].id : null)
        }
      ]
    ]) : rule.key => rule
  }

  security_group_id        = each.value.security_group_id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
}

resource "aws_security_group_rule" "egress" {
  for_each = {
    for rule in flatten([
      for sg_name, sg in var.security_groups : [
        for i, rule in lookup(sg, "egress_rules", []) : {
          key               = "${sg_name}-egress-${i}"
          security_group_id = aws_security_group.groups[sg_name].id
          type              = "egress"
          from_port         = rule.from_port
          to_port           = rule.to_port
          protocol          = rule.protocol
          cidr_blocks       = lookup(rule, "cidr_blocks", null)
        }
      ]
    ]) : rule.key => rule
  }

  security_group_id = each.value.security_group_id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
}

# Application Load Balancer
resource "aws_lb" "main" {
  count = var.create_alb ? 1 : 0

  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.groups["alb"].id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name = var.alb_name
  })
}

# Target Groups
resource "aws_lb_target_group" "main" {
  for_each = var.target_groups

  name     = "${var.name_prefix}-${each.key}-tg"
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = each.value.health_check_path
    port                = each.value.health_check_port
    protocol            = each.value.protocol
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${each.key}-tg"
  })
}

# ALB Listener
resource "aws_lb_listener" "main" {
  count = var.create_alb ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main["frontend"].arn
  }

  tags = var.common_tags
}

# ALB Listener Rules
resource "aws_lb_listener_rule" "main" {
  count = var.create_alb ? length(var.listener_rules) : 0

  listener_arn = aws_lb_listener.main[0].arn
  priority     = var.listener_rules[count.index].priority

  action {
    type             = var.listener_rules[count.index].actions[0].type
    target_group_arn = aws_lb_target_group.main[var.listener_rules[count.index].actions[0].target_group_key].arn
  }

  condition {
    path_pattern {
      values = var.listener_rules[count.index].conditions[0].path_pattern
    }
  }

  tags = var.common_tags
}

# EFS File System
resource "aws_efs_file_system" "main" {
  count = var.create_efs ? 1 : 0

  creation_token = var.efs_name
  encrypted      = true

  tags = merge(var.common_tags, {
    Name = var.efs_name
  })
}

# EFS Mount Targets
resource "aws_efs_mount_target" "main" {
  count = var.create_efs ? length(aws_subnet.private) : 0

  file_system_id  = aws_efs_file_system.main[0].id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs[0].id]
}

# EFS Security Group
resource "aws_security_group" "efs" {
  count = var.create_efs ? 1 : 0

  name_prefix = "${var.name_prefix}-efs-"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.groups["backend"].id, aws_security_group.groups["pipeline"].id]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-efs-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# AWS Secrets Manager
resource "aws_secretsmanager_secret" "main" {
  for_each = var.create_secrets ? var.secrets : {}

  name        = "${var.name_prefix}-${each.key}"
  description = each.value.description

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${each.key}"
  })
}

resource "aws_secretsmanager_secret_version" "main" {
  for_each = var.create_secrets ? var.secrets : {}

  secret_id = aws_secretsmanager_secret.main[each.key].id
  secret_string = jsonencode({
    placeholder = "Update this secret with actual values"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
} 