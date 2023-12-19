#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Paths to files
STACK_NAME="ollama-llama2-serverless"
CLOUDFORMATION_TEMPLATE="./cloudformation/iac.yaml"
PUSH_ECR_SCRIPT="./scripts/push_ecr.sh"

# Default values for image and repository names
DEFAULT_MODEL_NAME="llama2"

# Assign arguments to variables or use default values
MODEL_NAME="${1:-$DEFAULT_MODEL_NAME}"

IMAGE_NAME="ollama-${MODEL_NAME}-docker-20231213"
REPO_NAME="ollama-${MODEL_NAME}-repo-20231213"

echo "Setting up $MODEL_NAME model..."

# Run the script, print output in real-time, and capture it
SCRIPT_RESPONSE=$($PUSH_ECR_SCRIPT "$MODEL_NAME" "$IMAGE_NAME" "$REPO_NAME" | tee >(cat >&2))
ECR_IMAGE_URI=$(echo "$SCRIPT_RESPONSE" | tail -n 1)

# Deploy the CloudFormation stack
check_stack_status() {
  aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text
}

# Function to delete stack
delete_stack() {
  echo "Deleting stack $STACK_NAME..."
  aws cloudformation delete-stack --stack-name $STACK_NAME
  echo "Waiting for stack to be deleted..."
  aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
  echo "Stack deleted."
}

echo "Deploying CloudFormation stack..."
if ! aws cloudformation deploy \
  --template-file $CLOUDFORMATION_TEMPLATE \
  --stack-name $STACK_NAME \
  --parameter-overrides DockerImageUri="$ECR_IMAGE_URI" ModelName="$MODEL_NAME" \
  --capabilities CAPABILITY_IAM; then
  echo "Deployment failed. Checking stack status..."
  STACK_STATUS=$(check_stack_status)

  # If the stack is in ROLLBACK_COMPLETE state, delete it and try again
  if [ "$STACK_STATUS" = "ROLLBACK_COMPLETE" ]; then
    echo "Stack is in ROLLBACK_COMPLETE state."
    delete_stack
    echo "Redeploying the stack..."
    aws cloudformation deploy \
      --template-file $CLOUDFORMATION_TEMPLATE \
      --stack-name $STACK_NAME \
      --parameter-overrides DockerImageUri="$ECR_IMAGE_URI" ModelName="$MODEL_NAME" \
      --capabilities CAPABILITY_IAM
  else
    echo "Deployment failed with stack status: $STACK_STATUS"
    exit 1
  fi
fi