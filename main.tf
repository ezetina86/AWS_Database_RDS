# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Create Database Subnets
resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.20.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "${var.environment}-private-db-a"
  }
}

resource "aws_subnet" "private_db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.21.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "${var.environment}-private-db-b"
  }
}

resource "aws_subnet" "private_db_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.22.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "${var.environment}-private-db-c"
  }
}

# Create Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_db_b" {
  subnet_id      = aws_subnet.private_db_b.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_db_c" {
  subnet_id      = aws_subnet.private_db_c.id
  route_table_id = aws_route_table.private_rt.id
}

# EC2 Pool Security Group (referenced by MySQL security group)
resource "aws_security_group" "ec2_pool" {
  name        = "ec2_pool"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-ec2-pool"
  }
}

# MySQL Security Group
resource "aws_security_group" "mysql" {
  name        = "mysql"
  description = "Defines access to ghost db"
  vpc_id      = aws_vpc.main.id

  # Ingress rule for MySQL access from EC2 pool
  ingress {
    description     = "MySQL access from EC2 instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_pool.id]
  }

  # Egress rule - allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-mysql"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "ghost" {
  name        = "ghost"
  description = "Ghost database subnet group"
  subnet_ids = [
    aws_subnet.private_db_a.id,
    aws_subnet.private_db_b.id,
    aws_subnet.private_db_c.id
  ]

  tags = {
    Name = "${var.environment}-ghost-db-subnet-group"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "ghost" {
  identifier        = "ghost"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  # Database credentials
  username = var.db_username
  password = random_password.db_password.result

  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.ghost.name
  vpc_security_group_ids = [aws_security_group.mysql.id]

  # Database configuration
  db_name              = "ghostdb"
  parameter_group_name = "default.mysql8.0"

  # Backup and maintenance
  backup_retention_period = 7
  skip_final_snapshot     = true # Set to false in production

  # Enable deletion protection in production
  deletion_protection = false

  tags = {
    Name = "${var.environment}-ghost-db"
  }
}

# Generate random password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store password in SSM Parameter Store
resource "aws_ssm_parameter" "db_password" {
  name        = "/ghost/dbpassw"
  description = "Ghost database password"
  type        = "SecureString"
  value       = random_password.db_password.result

  tags = {
    Environment = var.environment
  }
}

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