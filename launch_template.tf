resource "aws_launch_template" "ghost" {
  name                   = "ghost"
  instance_type          = "t2.micro"
   image_id               = data.aws_ami.amazon_linux_2.id
  vpc_security_group_ids = [aws_security_group.ec2_pool.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ghost_app.name
  }

  key_name = aws_key_pair.ghost.key_name

  user_data = base64encode(<<-EOF
#!/bin/bash -xe
exec > >(tee /var/log/cloud-init-output.log|logger -t user-data -s 2>/dev/console) 2>&1

# Set variables
LB_DNS_NAME='${aws_lb.ghost.dns_name}'
SSM_DB_PASSWORD="/ghost/dbpassw"
REGION=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
DB_PASSWORD=$(aws ssm get-parameter --name $SSM_DB_PASSWORD --query Parameter.Value --with-decryption --region $REGION --output text)
DB_URL="${aws_db_instance.ghost.endpoint}"
DB_USER="${var.db_username}"
DB_NAME="ghostdb"
EFS_ID=$(aws efs describe-file-systems --query 'FileSystems[?Name==`ghost_content`].FileSystemId' --region $REGION --output text)

# Install prerequisites
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
yum install -y nodejs amazon-efs-utils
npm install ghost-cli@latest -g

# Create and configure ghost user
adduser ghost_user
usermod -aG wheel ghost_user
cd /home/ghost_user/

# Install Ghost
sudo -u ghost_user ghost install local

# Mount EFS
mkdir -p /home/ghost_user/ghost/content/data
mount -t efs -o tls $EFS_ID:/ /home/ghost_user/ghost/content

# Add EFS mount to fstab for persistence
echo "$EFS_ID:/ /home/ghost_user/ghost/content efs _netdev,tls 0 0" >> /etc/fstab

# Create Ghost config
cat << 'GHOST_CONFIG' > /home/ghost_user/ghost/config.production.json
{
  "url": "http://$LB_DNS_NAME",
  "server": {
    "port": 2368,
    "host": "0.0.0.0"
  },
  "database": {
    "client": "mysql",
    "connection": {
      "host": "$DB_URL",
      "port": 3306,
      "user": "$DB_USER",
      "password": "$DB_PASSWORD",
      "database": "$DB_NAME"
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
GHOST_CONFIG

# Set proper ownership
chown -R ghost_user:ghost_user /home/ghost_user/ghost

# Restart Ghost
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
