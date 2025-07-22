terraform {
  source = "../../../../modules/rds"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "network" {
  config_path = "../../../dev/network"
}

inputs = {
  service_name = "postgres"
  environment = "dev"
  
  # Database configuration
  engine = "postgres"
  engine_version = "17"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  max_allocated_storage = 100
  
  # Database settings
  database_name = "luciowl"
  username = "postgres"
  port = 5432
  
  # Security
  vpc_id = dependency.network.outputs.vpc_id
  subnet_ids = dependency.network.outputs.database_subnet_ids
  security_group_ids = [dependency.network.outputs.postgres_security_group_id]
  
  # Backup and maintenance
  backup_retention_period = 7
  backup_window = "03:00-04:00"
  maintenance_window = "sun:04:00-sun:05:00"
  
  # Development settings
  skip_final_snapshot = true
  deletion_protection = false
  
  # Performance insights
  performance_insights_enabled = false
  
  # Storage encryption
  storage_encrypted = true
  
  # Multi-AZ for high availability (disabled for dev)
  multi_az = false
  
  # Enhanced monitoring
  monitoring_interval = 0
  
  # Parameters and options
  parameter_group_name = "default.postgres17"
  option_group_name = "default:postgres-17"
  
  tags = {
    Service = "postgres"
    Environment = "dev"
  }
} 