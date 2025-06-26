#!/bin/bash

set -e

echo "=== Redis Infrastructure Deployment ==="

# Check if we're in the right directory
if [ ! -d "terraform" ]; then
    echo "Error: terraform directory not found. Please run this script from the project root."
    exit 1
fi

# Step 1: Create key pair if it doesn't exist
echo "Step 1: Checking/Creating key pair..."
if ! aws ec2 describe-key-pairs --key-names redis-infra-key --region ap-south-1 >/dev/null 2>&1; then
    echo "Creating key pair 'redis-infra-key'..."
    aws ec2 create-key-pair --key-name redis-infra-key --region ap-south-1 --query 'KeyMaterial' --output text > redis-infra-key.pem
    chmod 400 redis-infra-key.pem
    echo "Key pair created successfully!"
else
    echo "Key pair 'redis-infra-key' already exists."
    # Check if pem file exists locally
    if [ ! -f "redis-infra-key.pem" ]; then
        echo "Warning: Key pair exists in AWS but .pem file not found locally."
        echo "You may need to download or recreate the key pair."
    fi
fi

# Step 2: Clean up any conflicting resources
echo "Step 2: Cleaning up conflicting resources..."
if [ -f "./cleanup-conflicts.sh" ]; then
    ./cleanup-conflicts.sh
else
    echo "cleanup-conflicts.sh not found, skipping cleanup step."
fi

# Step 3: Initialize Terraform
echo "Step 3: Initializing Terraform..."
cd terraform
terraform init

# Step 4: Validate Terraform configuration
echo "Step 4: Validating Terraform configuration..."
terraform validate

# Step 5: Plan the deployment
echo "Step 5: Planning Terraform deployment..."
terraform plan -out=tfplan

# Step 6: Apply the deployment
echo "Step 6: Applying Terraform deployment..."
terraform apply tfplan

# Step 7: Get outputs
echo "Step 7: Getting deployment outputs..."
terraform output

echo "=== Deployment completed successfully! ==="
echo "Your Redis infrastructure is now ready."
echo ""
echo "To connect to your instances:"
echo "1. Public instance: ssh -i ../redis-infra-key.pem ubuntu@\$(terraform output -raw public-instance-ip)"
echo "2. Private instances: Connect via bastion host"
echo ""
echo "To configure Redis cluster, run Ansible playbook:"
echo "cd .. && ansible-playbook -i aws_ec2.yaml playbook.yml"
