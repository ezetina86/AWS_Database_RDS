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

  tags = {
    Name = "public_a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "${data.aws_region.current.name}b"

  tags = {
    Name = "public_b"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = "${data.aws_region.current.name}c"

  tags = {
    Name = "public_c"
  }
}

#######################
# Private DB Subnets
#######################
resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.20.0/24"
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Name = "private_db_a"
  }
}

resource "aws_subnet" "private_db_b" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.21.0/24"
  availability_zone = "${data.aws_region.current.name}b"

  tags = {
    Name = "private_db_b"
  }
}

resource "aws_subnet" "private_db_c" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.22.0/24"
  availability_zone = "${data.aws_region.current.name}c"

  tags = {
    Name = "private_db_c"
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
# Route Tables
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

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.cloudx.id

  tags = {
    Name = "private_rt"
  }
}

#######################
# Route Table Associations
#######################
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public_rt.id
}

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


# SSM VPC Endpoints
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.cloudx.id
  service_name        = "com.amazonaws.us-east-2.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id
  ]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.cloudx.id
  service_name        = "com.amazonaws.us-east-2.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id
  ]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.cloudx.id
  service_name        = "com.amazonaws.us-east-2.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id
  ]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.cloudx.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_pool.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#######################
# Private ECS Subnets
#######################
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.10.0/24"
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Name = "private_a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.11.0/24"
  availability_zone = "${data.aws_region.current.name}b"

  tags = {
    Name = "private_b"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = "10.10.12.0/24"
  availability_zone = "${data.aws_region.current.name}c"

  tags = {
    Name = "private_c"
  }
}

# Add route table associations for ECS private subnets
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private_rt.id
}
