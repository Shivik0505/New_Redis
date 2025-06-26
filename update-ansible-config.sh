#!/bin/bash

echo "=== Updating Ansible Configuration with Bastion Host ==="

# Get bastion host public IP
BASTION_IP=$(aws ec2 describe-instances \
    --region ap-south-1 \
    --filters "Name=tag:Name,Values=redis-public" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text)

if [ -z "$BASTION_IP" ]; then
    echo "❌ Could not find bastion host public IP"
    exit 1
fi

echo "✅ Found bastion host IP: $BASTION_IP"

# Update aws_ec2.yaml with bastion host configuration
cat > aws_ec2.yaml << EOF
---
plugin: aws_ec2
regions:
   - ap-south-1
filters:
  tag:Name:
    - "redis-private-1"
    - "redis-private-2"
    - "redis-private-3"
compose:
   ansible_host: private_ip_address
   ansible_ssh_private_key_file: "./redis-infra-key.pem"
   ansible_ssh_user: ubuntu
   # Use bastion host as jump server
   ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=60 -o ProxyCommand="ssh -W %h:%p -i ./redis-infra-key.pem -o StrictHostKeyChecking=no ubuntu@${BASTION_IP}"'
strict: False
cache: True
cache_timeout: 600
EOF

echo "✅ Updated aws_ec2.yaml with bastion host: $BASTION_IP"

# Test the configuration
echo "=== Testing Ansible Inventory ==="
ansible-inventory -i aws_ec2.yaml --list

echo "=== Configuration Update Complete ==="
