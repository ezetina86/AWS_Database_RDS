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