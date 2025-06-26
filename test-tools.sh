#!/bin/bash

echo "=== Testing Required Tools ==="

# Set PATH to include Homebrew
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "Current PATH: $PATH"
echo ""

echo "Testing AWS CLI..."
if command -v aws &> /dev/null; then
    echo "✅ AWS CLI found: $(which aws)"
    aws --version
else
    echo "❌ AWS CLI not found"
fi

echo ""
echo "Testing Terraform..."
if command -v terraform &> /dev/null; then
    echo "✅ Terraform found: $(which terraform)"
    terraform --version
else
    echo "❌ Terraform not found"
fi

echo ""
echo "Testing Ansible..."
if command -v ansible &> /dev/null; then
    echo "✅ Ansible found: $(which ansible)"
    ansible --version | head -1
else
    echo "❌ Ansible not found"
fi

echo ""
echo "Testing AWS credentials (if configured)..."
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS credentials are configured"
    aws sts get-caller-identity
else
    echo "⚠️  AWS credentials not configured or invalid"
fi

echo ""
echo "=== Tool Test Complete ==="
