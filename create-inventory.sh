#!/bin/bash

echo "=== Creating Ansible Inventory ==="

# Get instance information
BASTION_IP=$(aws ec2 describe-instances \
    --region ap-south-1 \
    --filters "Name=tag:Name,Values=redis-public" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text)

PRIVATE_IPS=$(aws ec2 describe-instances \
    --region ap-south-1 \
    --filters "Name=tag:Name,Values=redis-private-*" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0], PrivateIpAddress]' \
    --output text)

if [ -z "$BASTION_IP" ]; then
    echo "❌ Could not find bastion host"
    exit 1
fi

echo "✅ Bastion IP: $BASTION_IP"
echo "✅ Private instances found:"
echo "$PRIVATE_IPS"

# Create static inventory file
cat > inventory.ini << EOF
[bastion]
bastion ansible_host=$BASTION_IP ansible_ssh_private_key_file=./redis-infra-key.pem ansible_ssh_user=ubuntu

[redis_nodes]
EOF

# Add private instances to inventory
echo "$PRIVATE_IPS" | while read name ip; do
    if [ ! -z "$name" ] && [ ! -z "$ip" ]; then
        echo "$name ansible_host=$ip ansible_ssh_private_key_file=./redis-infra-key.pem ansible_ssh_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -i ./redis-infra-key.pem -o StrictHostKeyChecking=no ubuntu@$BASTION_IP\"'" >> inventory.ini
    fi
done

cat >> inventory.ini << EOF

[redis_nodes:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -i ./redis-infra-key.pem -o StrictHostKeyChecking=no ubuntu@$BASTION_IP"

[all:vars]
ansible_ssh_private_key_file=./redis-infra-key.pem
ansible_ssh_user=ubuntu
ansible_host_key_checking=False
EOF

echo "✅ Created inventory.ini:"
cat inventory.ini

echo "=== Testing Inventory ==="
ansible all -i inventory.ini -m ping

echo "=== Inventory Creation Complete ==="
