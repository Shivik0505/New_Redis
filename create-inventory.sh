#!/bin/bash

# Create Inventory Script for Jenkins Pipeline
# This script creates Ansible inventory from running AWS instances

set -e

echo "🔧 Creating Ansible inventory from AWS instances..."

# Get running instances
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

echo "Discovered instances:"
echo "  Bastion (Public): $PUBLIC_IP"
echo "  Redis Node 1: ${PRIVATE_IPS[0]}"
echo "  Redis Node 2: ${PRIVATE_IPS[1]}"
echo "  Redis Node 3: ${PRIVATE_IPS[2]}"

# Create inventory file
cat > inventory.ini << EOL
[bastion]
bastion ansible_host=$PUBLIC_IP ansible_user=ubuntu

[redis_nodes]
redis-node-1 ansible_host=${PRIVATE_IPS[0]} ansible_user=ubuntu
redis-node-2 ansible_host=${PRIVATE_IPS[1]} ansible_user=ubuntu
redis-node-3 ansible_host=${PRIVATE_IPS[2]} ansible_user=ubuntu

[redis_nodes:vars]
ansible_ssh_private_key_file=./redis-infra-key.pem
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -i ./redis-infra-key.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP"
ansible_python_interpreter=/usr/bin/python3

[all:vars]
ansible_ssh_user=ubuntu
ansible_ssh_private_key_file=./redis-infra-key.pem
EOL

echo "✅ Inventory created: inventory.ini"
echo "📋 Inventory contents:"
cat inventory.ini
