#!/bin/bash

# Create the key pair in ap-south-1 region
aws ec2 create-key-pair --key-name redis-demo-key --region ap-south-1 --query 'KeyMaterial' --output text > redis-demo-key.pem

# Set proper permissions
chmod 400 redis-demo-key.pem

echo "Key pair 'redis-demo-key' created successfully!"
echo "Private key saved as redis-demo-key.pem"
