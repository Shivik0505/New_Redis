#!/bin/bash

# Jenkins SSH Fix Script
# Run this in Jenkins pipeline to fix SSH connectivity

echo "🔧 Jenkins SSH Connectivity Fix"
echo "==============================="

# Set proper SSH key permissions
if [ -f "redis-infra-key.pem" ]; then
    chmod 400 redis-infra-key.pem
    echo "✅ SSH key permissions set"
else
    echo "❌ SSH key file not found"
    exit 1
fi

# Create improved inventory
./create-inventory-improved.sh

# Test SSH connectivity
echo "Testing SSH connectivity..."
timeout 60 ./test-ssh-connectivity.sh || {
    echo "❌ SSH connectivity test failed"
    echo "Checking security groups..."
    
    # Check security groups
    aws ec2 describe-security-groups \
        --region ap-south-1 \
        --filters "Name=group-name,Values=*redis*" \
        --query 'SecurityGroups[].{GroupName:GroupName,Rules:IpPermissions[?FromPort==`22`]}' \
        --output table
    
    echo "Manual SSH test commands:"
    PUBLIC_IP=$(aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:Name,Values=redis-public" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].PublicIpAddress' --output text)
    echo "ssh -i redis-infra-key.pem ubuntu@$PUBLIC_IP"
    
    exit 1
}

echo "✅ SSH connectivity verified"
