#######################
# ECR Repository
#######################
resource "aws_ecr_repository" "ghost" {
  name                 = "ghost"
  image_tag_mutability = "MUTABLE"  # Tag immutability disabled

  # Scan on push disabled
  image_scanning_configuration {
    scan_on_push = false
  }

  # KMS encryption disabled by default
}

resource "aws_ecr_lifecycle_policy" "ghost" {
  repository = aws_ecr_repository.ghost.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

