#!/bin/bash

# Create or update SSH config
CONFIG_FILE="$HOME/.ssh/config"
GENERATED_CONFIG="./ssh_config"

# Create .ssh directory if it doesn't exist
mkdir -p "$HOME/.ssh"

# Check if config file exists
if [ -f "$CONFIG_FILE" ]; then
    # Remove old Ghost configuration if it exists
    sed -i '/# Ghost Bastion SSH Configuration/,/# Ghost EC2 instances via Bastion/d' "$CONFIG_FILE"
fi

# Append new configuration
cat "$GENERATED_CONFIG" >> "$CONFIG_FILE"

# Set proper permissions
chmod 600 "$CONFIG_FILE"

echo "SSH configuration has been updated"
chmod +x setup_ssh.sh
