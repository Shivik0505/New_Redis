#!/bin/bash

echo "🧪 Testing Inventory Creation"
echo "============================"

# Test if AWS CLI works
if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "✅ AWS CLI is working"
else
    echo "❌ AWS CLI not configured"
    exit 1
fi

# Test inventory creation
if [ -f "create-inventory.sh" ]; then
    echo "📋 Running inventory creation..."
    ./create-inventory.sh
    
    if [ -f "inventory.ini" ]; then
        echo "✅ Inventory created successfully"
        echo "📄 Inventory contents:"
        cat inventory.ini
    else
        echo "❌ Inventory creation failed"
        exit 1
    fi
else
    echo "❌ create-inventory.sh not found"
    exit 1
fi
