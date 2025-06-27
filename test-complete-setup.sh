#!/bin/bash

echo "🧪 Testing Complete Ansible Setup"
echo "================================="

# Check if key file exists
if [ ! -f "redis-infra-key.pem" ]; then
    echo "❌ SSH key file not found: redis-infra-key.pem"
    exit 1
fi

chmod 400 redis-infra-key.pem
echo "✅ SSH key permissions set"

# Create inventory
echo "📋 Creating inventory..."
./create-clean-inventory.sh

# Test Ansible configuration
echo "🔧 Testing Ansible configuration..."
ansible-config dump | grep roles_path || echo "⚠️ roles_path not found in config"

# Test connectivity
echo "🔗 Testing connectivity..."
ansible all -i inventory.ini -m ping --timeout=30 || {
    echo "❌ Connectivity test failed"
    exit 1
}

echo "✅ Connectivity test passed"

# Test playbook syntax
echo "📝 Testing playbook syntax..."
ansible-playbook --syntax-check playbook.yml || {
    echo "❌ Playbook syntax check failed"
    exit 1
}

echo "✅ Playbook syntax is valid"

# Run playbook in check mode
echo "🚀 Running playbook in check mode..."
ansible-playbook -i inventory.ini playbook.yml --check --diff || {
    echo "❌ Playbook check mode failed"
    exit 1
}

echo "✅ Playbook check mode passed"
echo "🎉 All tests passed! Ready for deployment."
