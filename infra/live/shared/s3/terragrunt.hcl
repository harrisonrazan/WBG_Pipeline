terraform {
  source = "../../../modules/s3"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  # S3 bucket for pipeline data
  buckets = [
    {
      name = "luciowl-pipeline-data"
      versioning = true
      encryption = true
      
      # Lifecycle rules for cost optimization
      lifecycle_rules = [
        {
          id = "pipeline_data_lifecycle"
          status = "Enabled"
          
          transitions = [
            {
              days = 30
              storage_class = "STANDARD_IA"
            },
            {
              days = 90
              storage_class = "GLACIER"
            },
            {
              days = 365
              storage_class = "DEEP_ARCHIVE"
            }
          ]
          
          expiration = {
            days = 2555  # 7 years retention
          }
        }
      ]
      
      # CORS configuration for web access if needed
      cors_rules = [
        {
          allowed_headers = ["*"]
          allowed_methods = ["GET", "PUT", "POST"]
          allowed_origins = ["*"]
          expose_headers = ["ETag"]
          max_age_seconds = 3000
        }
      ]
    }
  ]
  
  # Public access settings (blocked for security)
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  
  tags = {
    Project = "luciowl"
    Environment = "shared"
    Purpose = "data-pipeline"
  }
} 