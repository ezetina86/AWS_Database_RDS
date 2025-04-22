# MySQL Security Group
resource "aws_security_group" "mysql" {
  name        = "mysql"
  description = "Defines access to ghost db"
  vpc_id      = aws_vpc.cloudx.id

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

  lifecycle {
    create_before_destroy = true
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

#######################
# Bastion Security Group
#######################
resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "Allows access to bastion"
  vpc_id      = aws_vpc.cloudx.id

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion"
  }
}
#######################
# EFS Security Group
#######################
resource "aws_security_group" "efs" {
  name        = "efs"
  description = "Defines access to efs mount points"
  vpc_id      = aws_vpc.cloudx.id

  ingress {
    description     = "NFS from EC2 pool"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_pool.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "efs"
  }
}

#######################
# EC2 Pool Security Group
#######################
resource "aws_security_group" "ec2_pool" {
  name        = "ec2_pool"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.cloudx.id

  # SSH access from bastion
  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # NFS access from VPC
  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # MySQL access (for database connectivity)
  ingress {
    description = "MySQL access from EC2 instances"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    self        = true
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ec2_pool"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

}

#######################
# ALB Security Group
#######################
resource "aws_security_group" "alb" {
  name        = "alb"
  description = "Allows access to alb"
  vpc_id      = aws_vpc.cloudx.id

  ingress {
    description = "HTTP from allowed IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb"
  }
}

# Add these separate security group rules after the security groups are created
resource "aws_security_group_rule" "ec2_pool_from_alb" {
  type                     = "ingress"
  from_port                = 2368
  to_port                  = 2368
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ec2_pool.id
}