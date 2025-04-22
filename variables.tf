variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  default     = "admin"
}