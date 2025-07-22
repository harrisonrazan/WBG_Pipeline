terraform {
  source = "../../../../modules/ecs"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "network" {
  config_path = "../../../dev/network"
}

dependency "ecr" {
  config_path = "../../../shared/ecr"
}

inputs = {
  service_name = "frontend"
  environment = "dev"
  
  # Container configuration
  container_image = "${dependency.ecr.outputs.frontend_repository_url}:latest"
  container_port = 3000
  cpu = 256
  memory = 512
  
  # Load balancer configuration
  health_check_path = "/"
  health_check_port = 3000
  
  # Environment variables
  environment_variables = [
    {
      name  = "REACT_APP_API_URL"
      value = "http://backend-dev.internal:8000"
    },
    {
      name  = "NODE_ENV"
      value = "development"
    },
    {
      name  = "CHOKIDAR_USEPOLLING"
      value = "true"
    },
    {
      name  = "CHOKIDAR_INTERVAL"
      value = "10"
    },
    {
      name  = "HOST"
      value = "0.0.0.0"
    }
  ]
  
  # Networking
  vpc_id = dependency.network.outputs.vpc_id
  subnet_ids = dependency.network.outputs.private_subnet_ids
  security_group_ids = [dependency.network.outputs.frontend_security_group_id]
  
  # Load balancer
  target_group_arn = dependency.network.outputs.frontend_target_group_arn
  
  # Auto scaling
  desired_count = 1
  min_capacity = 1
  max_capacity = 3
} 