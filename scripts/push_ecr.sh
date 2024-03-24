#!/bin/bash
# This requires aws configure to be run first

# Exit immediately if a command exits with a non-zero status.
set -e

# Check for required number of arguments
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <model-name> <image-name> <repo-name>"
  exit 1
fi

CURRENT_TIME_URI=$(date +%s)

# Assign arguments to variables
MODEL_NAME="$1"
IMAGE_NAME="$2"
REPO_NAME="$3"

echo "Pushing $MODEL_NAME model to ECR..."
echo "Image name: $IMAGE_NAME"
echo "Repository name: $REPO_NAME"

# Get AWS account ID and region from AWS configuration
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "Authenticating Docker with ECR..."
aws ecr get-login-password | docker login --username AWS --password-stdin "$ECR_URI"

# Create the ECR repository if it doesn't exist
if ! aws ecr describe-repositories --repository-names "$REPO_NAME" &>/dev/null; then
  echo "Creating ECR repository $REPO_NAME..."
  aws ecr create-repository --repository-name "$REPO_NAME"
fi

echo "Building Docker image..."
if ! docker build --platform linux/amd64 -t "$IMAGE_NAME" ./docker --build-arg MODEL_NAME="$MODEL_NAME"; then
  echo "Docker image failed to build."
  exit 1
fi
echo "Docker image built successfully."

FULL_URI="$ECR_URI"/"$REPO_NAME":"$CURRENT_TIME_URI"
docker tag "$IMAGE_NAME":latest "$FULL_URI"

echo "Pushing Docker image to ECR..."
docker push "$FULL_URI"

# Output the ECR URI for use in CloudFormation or elsewhere
echo "$FULL_URI"
