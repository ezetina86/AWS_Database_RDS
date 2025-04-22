variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = map(string)
  default = {
    "a" = "10.10.1.0/24"
    "b" = "10.10.2.0/24"
    "c" = "10.10.3.0/24"
  }
}

variable "allowed_ip" {
  description = "Your IP address for access"
  type        = string
  # default = "YOUR_IP/32"  # Replace with your IP or set via terraform.tfvars
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