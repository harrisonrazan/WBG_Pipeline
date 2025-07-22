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

inputs = {
  service_name = "backend"
  environment = "dev"
  
  # Container configuration
  container_image = "${dependency.ecr.outputs.backend_repository_url}:latest"
  container_port = 8000
  cpu = 512
  memory = 1024
  
  # Load balancer configuration
  health_check_path = "/health"
  health_check_port = 8000
  
  # Environment variables
  environment_variables = [
    {
      name  = "DATABASE_URL"
      value = "postgresql://${dependency.postgres.outputs.username}:${dependency.postgres.outputs.password}@${dependency.postgres.outputs.endpoint}/${dependency.postgres.outputs.database_name}"
    },
    {
      name  = "GOOGLE_DRIVE_BASE_FOLDER_ID"
      value = var.google_drive_base_folder_id
    }
  ]
  
  # Secrets for sensitive data
  secrets = [
    {
      name      = "GOOGLE_DRIVE_CREDENTIALS"
      valueFrom = dependency.network.outputs.google_drive_credentials_secret_arn
    }
  ]
  
  # Networking
  vpc_id = dependency.network.outputs.vpc_id
  subnet_ids = dependency.network.outputs.private_subnet_ids
  security_group_ids = [dependency.network.outputs.backend_security_group_id]
  
  # Load balancer
  target_group_arn = dependency.network.outputs.backend_target_group_arn
  
  # Auto scaling
  desired_count = 1
  min_capacity = 1
  max_capacity = 5
  
  # Volume mounts for queries
  volumes = [
    {
      name = "queries"
      efs_volume_configuration = {
        file_system_id = dependency.network.outputs.efs_file_system_id
        root_directory = "/queries"
      }
    }
  ]
  
  mount_points = [
    {
      sourceVolume  = "queries"
      containerPath = "/app/queries"
      readOnly      = true
    }
  ]
} 