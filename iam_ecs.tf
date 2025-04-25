#######################
# ECS Task Execution Role
#######################
resource "aws_iam_role" "ghost_ecs" {
  name = "ghost_ecs"

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

  tags = {
    Name = "ghost_ecs"
  }
}

#######################
# ECS Task Execution Policy
#######################
resource "aws_iam_policy" "ghost_ecs" {
  name        = "ghost_ecs_policy"
  description = "Policy for Ghost ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = "*"
      }
    ]
  })
}

#######################
# Attach Policy to Role
#######################
resource "aws_iam_role_policy_attachment" "ghost_ecs" {
  policy_arn = aws_iam_policy.ghost_ecs.arn
  role       = aws_iam_role.ghost_ecs.name
}

#######################
# Task Execution Role Profile
#######################
resource "aws_iam_instance_profile" "ghost_ecs" {
  name = "ghost_ecs"
  role = aws_iam_role.ghost_ecs.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ghost_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
