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
