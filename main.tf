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