#!/bin/bash

echo "🔗 Testing SSH Connectivity"
echo "=========================="

# Check if key file exists and has correct permissions
if [ ! -f "redis-infra-key.pem" ]; then
    echo "❌ SSH key file not found: redis-infra-key.pem"
    exit 1
fi

# Set correct permissions
chmod 400 redis-infra-key.pem
echo "✅ SSH key permissions set to 400"

# Get current IPs
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

echo "Testing connectivity to:"
echo "  Bastion: $PUBLIC_IP"
echo "  Redis nodes: ${PRIVATE_IPS[@]}"

# Test direct SSH to bastion
echo ""
echo "1. Testing direct SSH to bastion host..."
if timeout 30 ssh -i redis-infra-key.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP "echo 'Bastion SSH successful'" 2>/dev/null; then
    echo "✅ Direct SSH to bastion host successful"
else
    echo "❌ Direct SSH to bastion host failed"
    echo "Debugging SSH connection..."
    ssh -i redis-infra-key.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no -v ubuntu@$PUBLIC_IP "echo 'test'" 2>&1 | head -20
    exit 1
fi

# Test SSH through bastion to private nodes
echo ""
echo "2. Testing SSH through bastion to private nodes..."
for i in "${!PRIVATE_IPS[@]}"; do
    PRIVATE_IP=${PRIVATE_IPS[$i]}
    echo "Testing connection to redis-node-$((i+1)) ($PRIVATE_IP)..."
    
    if timeout 30 ssh -i redis-infra-key.pem \
        -o ProxyCommand="ssh -W %h:%p -i redis-infra-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=30 ubuntu@$PUBLIC_IP" \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=30 \
        ubuntu@$PRIVATE_IP "echo 'Redis node SSH successful'" 2>/dev/null; then
        echo "✅ SSH to redis-node-$((i+1)) successful"
    else
        echo "❌ SSH to redis-node-$((i+1)) failed"
        echo "Debugging connection..."
        ssh -i redis-infra-key.pem \
            -o ProxyCommand="ssh -W %h:%p -i redis-infra-key.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP" \
            -o StrictHostKeyChecking=no \
            -v ubuntu@$PRIVATE_IP "echo 'test'" 2>&1 | head -10
    fi
done

echo ""
echo "3. Testing Ansible connectivity..."
if [ -f "inventory_fixed.ini" ]; then
    ansible all -i inventory_fixed.ini -m ping --timeout=30
else
    echo "❌ inventory_fixed.ini not found"
    exit 1
fi

echo "✅ SSH connectivity test completed"
