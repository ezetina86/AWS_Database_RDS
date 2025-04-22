#######################
# VPC
#######################
resource "aws_vpc" "cloudx" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "cloudx"
  }
}

#######################
# Public Subnets
#######################
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "${data.aws_region.current.name}a"

  map_public_ip_on_launch = true

  tags = {
    Name = "public_a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "${data.aws_region.current.name}b"

  map_public_ip_on_launch = true

  tags = {
    Name = "public_b"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = "${data.aws_region.current.name}c"

  map_public_ip_on_launch = true

  tags = {
    Name = "public_c"
  }
}

#######################
# Internet Gateway
#######################
resource "aws_internet_gateway" "cloudx_igw" {
  vpc_id = aws_vpc.cloudx.id

  tags = {
    Name = "cloudx-igw"
  }
}

#######################
# Public Route Table
#######################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cloudx.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudx_igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

# Route table associations
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

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