resource "local_file" "ssh_config" {
  content = <<-EOF
# Ghost Bastion SSH Configuration
Host bastion
    HostName ${aws_instance.bastion.public_ip}
    User ec2-user
    IdentityFile ${path.module}/${var.ssh_key_name}.pem
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Ghost EC2 instances via Bastion
Host 10.10.*.*
    User ec2-user
    IdentityFile ${path.module}/${var.ssh_key_name}.pem
    ProxyCommand ssh bastion -W %h:%p
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

  filename = "${path.module}/ssh_config"
}
