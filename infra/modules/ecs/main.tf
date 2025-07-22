# ECS Module for Stack Sandbox Services
# This module creates ECS cluster, service, and task definitions

# ECS Cluster (shared across services)
resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-cluster"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.name_prefix}/${var.service_name}"
  retention_in_days = 30

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.service_name}-logs"
  })
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "task_execution" {
  name = "${var.name_prefix}-${var.service_name}-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.service_name}-task-execution"
  })
}

# Attach basic ECS task execution policy
resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "secrets_access" {
  count = length(var.secrets) > 0 ? 1 : 0
  name  = "${var.name_prefix}-${var.service_name}-secrets"
  role  = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [for secret in var.secrets : secret.valueFrom]
      }
    ]
  })
}

# IAM Role for ECS Task (application permissions)
resource "aws_iam_role" "task_role" {
  name = "${var.name_prefix}-${var.service_name}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.service_name}-task"
  })
}

# Attach additional policies to task role
resource "aws_iam_role_policy_attachment" "task_role_policies" {
  count      = length(var.task_role_policies)
  role       = aws_iam_role.task_role.name
  policy_arn = var.task_role_policies[count.index]
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name_prefix}-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn           = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.container_image
      essential = true

      portMappings = var.container_port > 0 ? [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ] : []

      environment = [for env in var.environment_variables : {
        name  = env.name
        value = env.value
      }]

      secrets = [for secret in var.secrets : {
        name      = secret.name
        valueFrom = secret.valueFrom
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Shared memory size for pipeline (Selenium)
      linuxParameters = var.shm_size > 0 ? {
        sharedMemorySize = var.shm_size
      } : null

      # Volume mounts
      mountPoints = var.mount_points

      # Health check
      healthCheck = var.container_port > 0 ? {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      } : null
    }
  ])

  # Volume definitions
  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name
      
      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", null) != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id     = efs_volume_configuration.value.file_system_id
          root_directory     = lookup(efs_volume_configuration.value, "root_directory", "/")
          transit_encryption = "ENABLED"
        }
      }
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.service_name}-task"
  })
}

# ECS Service (only for services, not scheduled tasks)
resource "aws_ecs_service" "main" {
  count = var.deployment_type == "service" ? 1 : 0

  name            = "${var.name_prefix}-${var.service_name}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  # Load balancer configuration (if target group provided)
  dynamic "load_balancer" {
    for_each = var.create_target_group && var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  # Auto scaling
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.service_name}-service"
  })
}

# Application Auto Scaling Target
resource "aws_appautoscaling_target" "main" {
  count = var.deployment_type == "service" ? 1 : 0

  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = var.common_tags
}

# Auto Scaling Policy - Scale Up
resource "aws_appautoscaling_policy" "scale_up" {
  count = var.deployment_type == "service" ? 1 : 0

  name               = "${var.name_prefix}-${var.service_name}-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main[0].resource_id
  scalable_dimension = aws_appautoscaling_target.main[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# CloudWatch Event Rule for scheduled tasks (pipeline)
resource "aws_cloudwatch_event_rule" "scheduled_task" {
  count = var.deployment_type == "scheduled" ? 1 : 0

  name                = "${var.name_prefix}-${var.service_name}-schedule"
  description         = "Trigger for ${var.service_name} scheduled task"
  schedule_expression = var.schedule_expression

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.service_name}-schedule"
  })
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "scheduled_task" {
  count = var.deployment_type == "scheduled" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.scheduled_task[0].name
  target_id = "${var.service_name}Target"
  arn       = aws_ecs_cluster.main.arn
  role_arn  = aws_iam_role.events_execution[0].arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.main.arn
    launch_type         = "FARGATE"

    network_configuration {
      subnets          = var.subnet_ids
      security_groups  = var.security_group_ids
      assign_public_ip = false
    }
  }
}

# IAM role for CloudWatch Events
resource "aws_iam_role" "events_execution" {
  count = var.deployment_type == "scheduled" ? 1 : 0
  name  = "${var.name_prefix}-${var.service_name}-events"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.service_name}-events"
  })
}

resource "aws_iam_role_policy" "events_execution" {
  count = var.deployment_type == "scheduled" ? 1 : 0
  name  = "${var.name_prefix}-${var.service_name}-events"
  role  = aws_iam_role.events_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = aws_ecs_task_definition.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.task_execution.arn,
          aws_iam_role.task_role.arn
        ]
      }
    ]
  })
} 