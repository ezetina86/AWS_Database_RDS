# Create IAM Policy for SSM Parameter Store access
resource "aws_iam_policy" "ssm_access" {
  name        = "SSMParameterStoreAccess"
  description = "Allows access to SSM Parameter Store, Secrets Manager, and KMS decrypt"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter*"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/ghost/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ghost/*"
        ]
      }
    ]
  })
}

# Add these data sources at the top of your configuration
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Create IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "EC2SSMParameterStoreAccess"

  # Trust relationship policy allowing EC2 to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-ec2-ssm-role"
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  policy_arn = aws_iam_policy.ssm_access.arn
  role       = aws_iam_role.ec2_role.name
}

# Create an instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2SSMParameterStoreAccess"
  role = aws_iam_role.ec2_role.name
}

# IAM Role
resource "aws_iam_role" "ghost_app" {
  name = "ghost_app"

  # Trust relationship policy allowing EC2 to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ghost_app"
  }
}

# IAM Policy
resource "aws_iam_policy" "ghost_app" {
  name        = "ghost_app_policy"
  description = "Policy for Ghost application EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ghost_app" {
  policy_arn = aws_iam_policy.ghost_app.arn
  role       = aws_iam_role.ghost_app.name
}

# Create instance profile
resource "aws_iam_instance_profile" "ghost_app" {
  name = "ghost_app"
  role = aws_iam_role.ghost_app.name
}