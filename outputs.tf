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

output "bastion_sg_id" {
  description = "The ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "ec2_pool_sg_id" {
  description = "The ID of the EC2 pool security group"
  value       = aws_security_group.ec2_pool.id
}

output "alb_sg_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "efs_sg_id" {
  description = "The ID of the EFS security group"
  value       = aws_security_group.efs.id
}

output "key_pair_name" {
  value = aws_key_pair.ghost.key_name
}

output "private_key_path" {
  value = local_file.private_key.filename
}

output "ghost_app_role_arn" {
  description = "ARN of the Ghost application IAM role"
  value       = aws_iam_role.ghost_app.arn
}

output "ghost_app_instance_profile_arn" {
  description = "ARN of the Ghost application instance profile"
  value       = aws_iam_instance_profile.ghost_app.arn
}

output "ghost_app_instance_profile_name" {
  description = "Name of the Ghost application instance profile"
  value       = aws_iam_instance_profile.ghost_app.name
}

output "efs_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.ghost_content.id
}

output "efs_dns_name" {
  description = "DNS name of the EFS file system"
  value       = aws_efs_file_system.ghost_content.dns_name
}

output "efs_mount_targets" {
  description = "Mount target IDs and IPs"
  value = {
    az_a = {
      id = aws_efs_mount_target.az_a.id
      ip = aws_efs_mount_target.az_a.ip_address
    }
    az_b = {
      id = aws_efs_mount_target.az_b.id
      ip = aws_efs_mount_target.az_b.ip_address
    }
    az_c = {
      id = aws_efs_mount_target.az_c.id
      ip = aws_efs_mount_target.az_c.ip_address
    }
  }
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.ghost.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.ghost.zone_id
}

output "target_group_arn" {
  description = "ARN of the Ghost EC2 target group"
  value       = aws_lb_target_group.ghost_ec2.arn
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.ghost.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.ghost.id
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.ghost.latest_version
}

output "instance_id" {
  description = "ID of the Ghost EC2 instance"
  value       = aws_instance.ghost.id
}

output "instance_public_ip" {
  description = "Public IP of the Ghost EC2 instance"
  value       = aws_instance.ghost.public_ip
}
