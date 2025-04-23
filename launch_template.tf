resource "random_string" "launch_template_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_launch_template" "ghost" {
  name                   = "ghost-${random_string.launch_template_suffix.result}"
  instance_type          = "t2.micro"
  image_id               = data.aws_ami.amazon_linux_2023.id
  vpc_security_group_ids = [aws_security_group.ec2_pool.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ghost_app.name
  }

  key_name = aws_key_pair.ghost.key_name

  # Add IMDSv2 settings
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # Set to optional as recommended
    http_put_response_hop_limit = 2
  }


  user_data = base64encode(<<-EOF
#!/bin/bash -xe

exec > >(tee /var/log/cloud-init-output.log|logger -t user-data -s 2>/dev/console) 2>&1

# Set variables
LB_DNS_NAME='${aws_lb.ghost.dns_name}'
REGION=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
EFS_ID=$(aws efs describe-file-systems --query 'FileSystems[?Name==`ghost_content`].FileSystemId' --region $REGION --output text)

echo "EFS_ID: $EFS_ID"
echo "REGION: $REGION"

### Install pre-reqs
echo "Installing node js..."
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs
echo "Installing amazon-efs-utils and ghost-cli..."
sudo yum install -y amazon-efs-utils
sudo npm install -g ghost-cli@latest

### Add ghost_user
if ! id "ghost_user" &>/dev/null; then
    echo "Adding user ghost_user"
    adduser ghost_user
    usermod -aG wheel ghost_user
else
    echo "User ghost_user already exists. Skipping user creation."
fi

# Create the directory and set ownership
if [ ! -d "/home/ghost_user/ghost" ]; then
    echo "Creating ghost folder"
    sudo mkdir -p /home/ghost_user/ghost
    sudo chown -R ghost_user:ghost_user /home/ghost_user/ghost
else
    echo "Folder already exists. Skipping ghost folder creation."
fi

# Switch to ghost_user and proceed
echo "Installing ghost..."
sudo su - ghost_user -c "cd /home/ghost_user/ghost && ghost install --version 5 local"

### EFS mount
echo "Mounting efs..."
echo "EFS_ID: $EFS_ID"
mkdir -p /home/ghost_user/ghost/content/data
mount -t efs -o tls $EFS_ID:/ /home/ghost_user/ghost/content

echo "Setting permissions..."
chown -R ghost_user:ghost_user /home/ghost_user/ghost/content
sudo chmod -R u+rwX /home/ghost_user/ghost/content

echo "Creating config.development.json"
cat > /home/ghost_user/ghost/config.development.json << 'CONFIGEND'
{
  "url": "http://${aws_lb.ghost.dns_name}",
  "server": {
    "port": 2368,
    "host": "0.0.0.0"
  },
  "database": {
    "client": "sqlite3",
    "connection": {
      "filename": "/home/ghost_user/ghost/content/data/ghost-local.db"
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
  "process": "local",
  "paths": {
    "contentPath": "/home/ghost_user/ghost/content"
  }
}
CONFIGEND

# Ensure ghost commands are executed in the correct directory
echo "Stopping Ghost..."
sudo -u ghost_user bash -c "cd /home/ghost_user/ghost && ghost stop"

echo "Starting Ghost..."
sudo -u ghost_user bash -c "cd /home/ghost_user/ghost && ghost start"

echo "Installation complete!"
EOF
  )

  tags = {
    Name = "ghost-launch-template"
  }

  lifecycle {
    create_before_destroy = true
  }
}
