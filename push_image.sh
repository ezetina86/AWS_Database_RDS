#!/bin/bash

# Set variables
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "Getting ECR password..."
ECR_PASSWORD=$(aws ecr get-login-password --region $REGION)

echo "Logging into ECR..."
# Login to ECR using podman
echo $ECR_PASSWORD | podman login --username AWS --password-stdin $REPO_URL

echo "Pulling Ghost image..."
# Pull the Ghost image (with platform specification for M1)
podman pull --platform linux/amd64 docker.io/library/ghost:4.12.1

echo "Tagging image..."
# Tag the image for ECR
podman tag docker.io/library/ghost:4.12.1 $REPO_URL/ghost:4.12.1

echo "Pushing image to ECR..."
# Push the image to ECR
podman push $REPO_URL/ghost:4.12.1

echo "Done!"
