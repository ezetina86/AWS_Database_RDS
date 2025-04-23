resource "random_string" "launch_template_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_launch_template" "ghost" {
  name                   = "ghost-${random_string.launch_template_suffix.result}"
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

# Add retry logic for SSM parameter
MAX_RETRIES=5
RETRY_DELAY=10
for i in $(seq 1 $MAX_RETRIES); do
    echo "Attempting to get SSM parameter (attempt $i of $MAX_RETRIES)"
    DB_PASSWORD=$(aws ssm get-parameter --name $SSM_DB_PASSWORD --query Parameter.Value --with-decryption --region $REGION --output text)
    if [ $? -eq 0 ] && [ ! -z "$DB_PASSWORD" ]; then
        break
    fi
    sleep $RETRY_DELAY
done

if [ -z "$DB_PASSWORD" ]; then
    echo "Failed to retrieve database password from SSM"
    exit 1
fi

DB_URL="${aws_db_instance.ghost.endpoint}"
DB_USER="${var.db_username}"
DB_NAME="ghostdb"
EFS_ID=$(aws efs describe-file-systems --query 'FileSystems[?Name==`ghost_content`].FileSystemId' --region $REGION --output text)

# Install prerequisites
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
yum install -y nodejs amazon-efs-utils mysql
npm install ghost-cli@latest -g

# Create and configure ghost user
adduser ghost_user
usermod -aG wheel ghost_user
cd /home/ghost_user/

# Mount EFS first
mkdir -p /home/ghost_user/ghost/content
mount -t efs -o tls $EFS_ID:/ /home/ghost_user/ghost/content

# Add EFS mount to fstab for persistence
echo "$EFS_ID:/ /home/ghost_user/ghost/content efs _netdev,tls 0 0" >> /etc/fstab

# Install Ghost
sudo -u ghost_user ghost install local

# Create Ghost config
cat > /home/ghost_user/ghost/config.production.json << 'ENDCONFIG'
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
ENDCONFIG

# Set proper ownership
chown -R ghost_user:ghost_user /home/ghost_user/ghost

# Create systemd service file
cat > /etc/systemd/system/ghost_ghost.service << 'ENDSERVICE'
[Unit]
Description=Ghost Blog
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/ghost_user/ghost
User=ghost_user
Environment="NODE_ENV=production"
ExecStart=/usr/bin/node current/index.js
Restart=always

[Install]
WantedBy=multi-user.target
ENDSERVICE

# Start Ghost
systemctl daemon-reload
systemctl enable ghost_ghost
systemctl start ghost_ghost

# Wait for Ghost to start
sleep 30

# Verify Ghost is running
curl -v http://localhost:2368
EOF
  )

  tags = {
    Name = "ghost-launch-template"
  }

  lifecycle {
    create_before_destroy = true
  }
}
