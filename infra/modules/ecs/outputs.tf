# Outputs for ECS module

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_id" {
  description = "ID of the ECS service"
  value       = var.deployment_type == "service" ? aws_ecs_service.main[0].id : null
}

output "service_name" {
  description = "Name of the ECS service"
  value       = var.deployment_type == "service" ? aws_ecs_service.main[0].name : null
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = aws_iam_role.task_role.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.name
}

output "scheduled_task_rule_arn" {
  description = "ARN of the CloudWatch Events rule for scheduled tasks"
  value       = var.deployment_type == "scheduled" ? aws_cloudwatch_event_rule.scheduled_task[0].arn : null
} 