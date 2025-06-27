#!/bin/bash

# Ansible Connection Test Script
# Tests connectivity to all Redis nodes

set -e

echo "🧪 Testing Ansible Connectivity"
echo "==============================="

# Check if key file exists
if [ ! -f "redis-infra-key.pem" ]; then
    echo "❌ SSH key file not found: redis-infra-key.pem"
    exit 1
fi

# Set proper permissions
chmod 400 redis-infra-key.pem

# Create dynamic inventory
if [ -f "create_dynamic_inventory.sh" ]; then
    echo "📋 Creating dynamic inventory..."
    ./create_dynamic_inventory.sh
else
    echo "⚠️ Dynamic inventory script not found, using existing inventory"
fi

# Test connectivity
echo "🔗 Testing connectivity to all hosts..."

if [ -f "inventory_dynamic.ini" ]; then
    INVENTORY="inventory_dynamic.ini"
elif [ -f "aws_ec2.yaml" ]; then
    INVENTORY="aws_ec2.yaml"
else
    echo "❌ No inventory file found"
    exit 1
fi

echo "Using inventory: $INVENTORY"

# Test ping to all hosts
echo "Testing ping connectivity..."
ansible all -i $INVENTORY -m ping --timeout=30 || {
    echo "❌ Ping test failed"
    echo "Debugging connection issues..."
    
    # Debug bastion connectivity
    if [ -f "inventory_dynamic.ini" ]; then
        BASTION_IP=$(grep "bastion ansible_host=" inventory_dynamic.ini | cut -d'=' -f2 | cut -d' ' -f1)
        echo "Testing direct SSH to bastion: $BASTION_IP"
        ssh -i redis-infra-key.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$BASTION_IP "echo 'Bastion SSH OK'" || echo "❌ Bastion SSH failed"
    fi
    
    exit 1
}

echo "✅ Ansible connectivity test passed!"

# Test gathering facts
echo "🔍 Testing fact gathering..."
ansible all -i $INVENTORY -m setup -a "filter=ansible_default_ipv4" --timeout=30 || {
    echo "⚠️ Fact gathering failed, but connectivity works"
}

echo "✅ Ansible connection test completed successfully!"
