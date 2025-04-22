#######################
# Launch Template
#######################
resource "aws_launch_template" "ghost" {
  name                   = "ghost"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_pool.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ghost_app.name
  }

  key_name = aws_key_pair.ghost.key_name

  user_data = base64encode(<<-EOF
#!/bin/bash -xe
exec > >(tee /var/log/cloud-init-output.log|logger -t user-data -s 2>/dev/console) 2>&1

### Update this to match your ALB DNS name
LB_DNS_NAME='${aws_lb.ghost.dns_name}'
###

REGION=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
EFS_ID=$(aws efs describe-file-systems --query 'FileSystems[?Name==`ghost_content`].FileSystemId' --region $REGION --output text)

### Install pre-reqs
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
yum install -y nodejs amazon-efs-utils
npm install ghost-cli@latest -g

adduser ghost_user
usermod -aG wheel ghost_user
cd /home/ghost_user/

sudo -u ghost_user ghost install local

### EFS mount
mkdir -p /home/ghost_user/ghost/content/data
mount -t efs -o tls $EFS_ID:/ /home/ghost_user/ghost/content

cat << 'EOT' > /home/ghost_user/ghost/config.production.json
{
  "url": "http://${aws_lb.ghost.dns_name}",
  "server": {
    "port": 2368,
    "host": "0.0.0.0"
  },
  "database": {
    "client": "mysql",
    "connection": {
      "host": "${aws_db_instance.ghost.endpoint}",
      "port": 3306,
      "user": "${var.db_username}",
      "password": "${random_password.db_password.result}",
      "database": "ghostdb"
    }
  },
  "mail": {
    "transport": "Direct"
  },
  "logging": {
    "transports": [
      "file",
      "stdout"
    ]
  },
  "process": "systemd",
  "paths": {
    "contentPath": "/home/ghost_user/ghost/content"
  }
}
EOT

chown ghost_user:ghost_user -R /home/ghost_user/ghost

sudo -u ghost_user ghost stop
sudo -u ghost_user ghost start

# Enable Ghost service
systemctl enable ghost_ghost
EOF
  )

  tags = {
    Name = "ghost-launch-template"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#######################
# Data Source for Amazon Linux 2 AMI
#######################
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#######################
# Single EC2 Instance
#######################
resource "aws_instance" "ghost" {
  launch_template {
    id      = aws_launch_template.ghost.id
    version = "$Latest"
  }

  subnet_id = aws_subnet.public_a.id  # You might want to use a private subnet in production

  tags = {
    Name = "ghost-instance"
  }
}

# Register the instance with the target group
resource "aws_lb_target_group_attachment" "ghost" {
  target_group_arn = aws_lb_target_group.ghost_ec2.arn
  target_id        = aws_instance.ghost.id
  port             = 2368
}
