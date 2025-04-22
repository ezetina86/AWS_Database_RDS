# Generate random password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store password in SSM Parameter Store
resource "aws_ssm_parameter" "db_password" {
  name        = "/ghost/dbpassw"
  description = "Ghost database password"
  type        = "SecureString"
  value       = random_password.db_password.result

  tags = {
    Environment = var.environment
  }
}