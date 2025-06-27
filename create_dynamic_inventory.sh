#!/bin/bash

# Dynamic Inventory Creation Script for Jenkins
# Creates Ansible inventory from Terraform outputs

set -e

echo "Creating dynamic Ansible inventory..."

# Get Terraform outputs
if [ -f "terraform-outputs.json" ]; then
    echo "Using existing terraform-outputs.json"
else
    echo "Generating Terraform outputs..."
    cd terraform
    terraform output -json > ../terraform-outputs.json
    cd ..
fi

# Extract IPs from Terraform outputs
PUBLIC_IP=$(jq -r '.["public-instance-ip"].value' terraform-outputs.json 2>/dev/null || echo "")
PRIVATE_IP_1=$(jq -r '.["private-instance1-ip"].value' terraform-outputs.json 2>/dev/null || echo "")
PRIVATE_IP_2=$(jq -r '.["private-instance2-ip"].value' terraform-outputs.json 2>/dev/null || echo "")
PRIVATE_IP_3=$(jq -r '.["private-instance3-ip"].value' terraform-outputs.json 2>/dev/null || echo "")

# Fallback to AWS CLI if Terraform outputs not available
if [ -z "$PUBLIC_IP" ] || [ -z "$PRIVATE_IP_1" ]; then
    echo "Terraform outputs not available, using AWS CLI..."
    
    PUBLIC_IP=$(aws ec2 describe-instances \
        --region ap-south-1 \
        --filters "Name=tag:Name,Values=redis-public" "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].PublicIpAddress' \
        --output text)
    
    PRIVATE_IPS=($(aws ec2 describe-instances \
        --region ap-south-1 \
        --filters "Name=tag:Name,Values=redis-private*" "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].PrivateIpAddress' \
        --output text))
    
    PRIVATE_IP_1=${PRIVATE_IPS[0]}
    PRIVATE_IP_2=${PRIVATE_IPS[1]}
    PRIVATE_IP_3=${PRIVATE_IPS[2]}
fi

echo "Discovered IPs:"
echo "  Bastion (Public): $PUBLIC_IP"
echo "  Redis Node 1: $PRIVATE_IP_1"
echo "  Redis Node 2: $PRIVATE_IP_2"
echo "  Redis Node 3: $PRIVATE_IP_3"

# Create inventory file
cat > inventory_dynamic.ini << EOL
[bastion]
bastion ansible_host=$PUBLIC_IP ansible_user=ubuntu

[redis_nodes]
redis-node-1 ansible_host=$PRIVATE_IP_1 ansible_user=ubuntu
redis-node-2 ansible_host=$PRIVATE_IP_2 ansible_user=ubuntu
redis-node-3 ansible_host=$PRIVATE_IP_3 ansible_user=ubuntu

[redis_nodes:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -i ./redis-infra-key.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP"

[all:vars]
ansible_ssh_private_key_file=./redis-infra-key.pem
ansible_ssh_user=ubuntu
ansible_python_interpreter=/usr/bin/python3
EOL

echo "✅ Dynamic inventory created: inventory_dynamic.ini"
