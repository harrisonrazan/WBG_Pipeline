terraform {
  source = "../../../modules/ecr"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  # Create repositories for each service
  repositories = [
    {
      name = "luciowl/frontend"
      image_tag_mutability = "MUTABLE"
      scan_on_push = true
    },
    {
      name = "luciowl/backend"
      image_tag_mutability = "MUTABLE"
      scan_on_push = true
    },
    {
      name = "luciowl/pipeline"
      image_tag_mutability = "MUTABLE"
      scan_on_push = true
    }
  ]
  
  # Lifecycle policies to manage storage costs
  lifecycle_policy = {
    rules = [
      {
        rulePriority = 1
        description = "Keep last 30 images"
        selection = {
          tagStatus = "any"
          countType = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  }
  
  tags = {
    Project = "luciowl"
    Environment = "shared"
  }
} 