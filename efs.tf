#######################
# EFS File System
#######################
resource "aws_efs_file_system" "ghost_content" {
  creation_token = "ghost_content"
  encrypted      = true

  tags = {
    Name = "ghost_content"
  }
}

#######################
# EFS Mount Targets
#######################
# Mount target for AZ-a
resource "aws_efs_mount_target" "az_a" {
  file_system_id  = aws_efs_file_system.ghost_content.id
  subnet_id       = aws_subnet.private_db_a.id
  security_groups = [aws_security_group.efs.id]
}

# Mount target for AZ-b
resource "aws_efs_mount_target" "az_b" {
  file_system_id  = aws_efs_file_system.ghost_content.id
  subnet_id       = aws_subnet.private_db_b.id
  security_groups = [aws_security_group.efs.id]
}

# Mount target for AZ-c
resource "aws_efs_mount_target" "az_c" {
  file_system_id  = aws_efs_file_system.ghost_content.id
  subnet_id       = aws_subnet.private_db_c.id
  security_groups = [aws_security_group.efs.id]
}