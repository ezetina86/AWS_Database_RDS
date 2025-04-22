# Generate private key
resource "tls_private_key" "ghost" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "ghost" {
  key_name   = var.ssh_key_name
  public_key = tls_private_key.ghost.public_key_openssh

  tags = {
    Name = var.ssh_key_name
  }
}

# Store private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ghost.private_key_pem
  filename        = "${path.module}/${var.ssh_key_name}.pem"
  file_permission = "0400"
}