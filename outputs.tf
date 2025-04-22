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