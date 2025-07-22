terraform {
  source = "../../../../modules/ecs"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "network" {
  config_path = "../../../dev/network"
}

dependency "postgres" {
  config_path = "../postgres"
}

dependency "ecr" {
  config_path = "../../../shared/ecr"
}

dependency "s3" {
  config_path = "../../../shared/s3"
}

inputs = {
  service_name = "pipeline"
  environment = "dev"
  
  # Container configuration
  container_image = "${dependency.ecr.outputs.pipeline_repository_url}:latest"
  container_port = 8080  # Internal port for health checks
  cpu = 1024
  memory = 4096  # 4GB as specified in docker-compose
  
  # Shared memory for browser (Selenium)
  shm_size = 2048  # 2GB as specified in docker-compose
  
  # Environment variables
  environment_variables = [
    {
      name  = "DATABASE_URL"
      value = "postgresql://${dependency.postgres.outputs.username}:${dependency.postgres.outputs.password}@${dependency.postgres.outputs.endpoint}/${dependency.postgres.outputs.database_name}"
    },
    {
      name  = "S3_BUCKET"
      value = dependency.s3.outputs.pipeline_bucket_name
    },
    {
      name  = "AWS_DEFAULT_REGION"
      value = "us-east-1"
    }
  ]
  
  # Networking
  vpc_id = dependency.network.outputs.vpc_id
  subnet_ids = dependency.network.outputs.private_subnet_ids
  security_group_ids = [dependency.network.outputs.pipeline_security_group_id]
  
  # No load balancer for pipeline (internal service)
  create_target_group = false
  
  # Scheduled task configuration (not always running)
  deployment_type = "scheduled"  # Can be "service" or "scheduled"
  
  # Auto scaling (for service deployment)
  desired_count = 0  # Start with 0, run on schedule
  min_capacity = 0
  max_capacity = 1
  
  # IAM permissions for S3 and other AWS services
  task_role_policies = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
  
  # CloudWatch Events rule for scheduling
  schedule_expression = "rate(6 hours)"  # Run every 6 hours
  
  tags = {
    Service = "pipeline"
    Environment = "dev"
    Type = "data-processing"
  }
} 