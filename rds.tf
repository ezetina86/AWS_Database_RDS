# rds.tf
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_rds_cluster" "main" {
  cluster_identifier     = "${var.project_name}-db-cluster"
  engine                = "aurora-mysql"
  engine_version        = "8.0.mysql_aurora.3.04.0"
  database_name         = var.database_name
  master_username       = var.database_username
  master_password       = var.database_password
  db_subnet_group_name  = aws_db_subnet_group.main.name
  skip_final_snapshot   = true
  vpc_security_group_ids = [aws_security_group.rds.id]

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
}

resource "aws_rds_cluster_instance" "main" {
  count               = 2
  identifier          = "${var.project_name}-db-instance-${count.index + 1}"
  cluster_identifier  = aws_rds_cluster.main.id
  instance_class      = "db.r5.large"
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id, aws_security_group.ecs_tasks.id]
  }
}
