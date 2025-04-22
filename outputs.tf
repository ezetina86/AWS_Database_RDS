output "vpc_id_x" {
  description = "The ID of the VPC"
  value       = aws_vpc.cloudx.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
    aws_subnet.public_c.id
  ]
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.cloudx.cidr_block
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public_rt.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_db_subnet_ids" {
  value = [
    aws_subnet.private_db_a.id,
    aws_subnet.private_db_b.id,
    aws_subnet.private_db_c.id
  ]
}

output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}

output "mysql_security_group_id" {
  value = aws_security_group.mysql.id
}

output "ec2_pool_security_group_id" {
  value = aws_security_group.ec2_pool.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.ghost.name
}

output "rds_endpoint" {
  value = aws_db_instance.ghost.endpoint
}

output "rds_port" {
  value = aws_db_instance.ghost.port
}

output "ssm_parameter_name" {
  value = aws_ssm_parameter.db_password.name
}

output "iam_role_arn" {
  value = aws_iam_role.ec2_role.arn
}

output "iam_role_name" {
  value = aws_iam_role.ec2_role.name
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}