#!/bin/bash

echo "=== AWS Region Configuration ==="

# Get current AWS CLI region
AWS_CLI_REGION=$(aws configure get region 2>/dev/null || echo "not set")
echo "Current AWS CLI region: $AWS_CLI_REGION"

# Get current Terraform region
TERRAFORM_REGION=$(grep -r "region.*=" terraform/provider.tf | cut -d'"' -f2 2>/dev/null || echo "not found")
echo "Current Terraform region: $TERRAFORM_REGION"

if [ "$AWS_CLI_REGION" != "$TERRAFORM_REGION" ]; then
    echo ""
    echo "⚠️  Region mismatch detected!"
    echo "AWS CLI is configured for: $AWS_CLI_REGION"
    echo "Terraform is configured for: $TERRAFORM_REGION"
    echo ""
    echo "Please choose which region to use:"
    echo "1. Use AWS CLI region ($AWS_CLI_REGION) - Update Terraform"
    echo "2. Use Terraform region ($TERRAFORM_REGION) - Update AWS CLI"
    echo "3. Manually specify a different region"
    echo ""
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            echo "Updating Terraform to use region: $AWS_CLI_REGION"
            sed -i.bak "s/region = \".*\"/region = \"$AWS_CLI_REGION\"/" terraform/provider.tf
            
            # Update AMI ID for the new region (this is a basic example)
            echo "⚠️  Note: You may need to update the AMI ID in terraform/instances/variable.tf"
            echo "Current AMI is for ap-south-1. Please verify it works in $AWS_CLI_REGION"
            ;;
        2)
            echo "Updating AWS CLI to use region: $TERRAFORM_REGION"
            aws configure set region $TERRAFORM_REGION
            echo "AWS CLI region updated to: $TERRAFORM_REGION"
            ;;
        3)
            read -p "Enter the region you want to use: " new_region
            echo "Updating both AWS CLI and Terraform to use: $new_region"
            aws configure set region $new_region
            sed -i.bak "s/region = \".*\"/region = \"$new_region\"/" terraform/provider.tf
            echo "⚠️  Note: You may need to update the AMI ID in terraform/instances/variable.tf"
            ;;
        *)
            echo "Invalid choice. Please run the script again."
            exit 1
            ;;
    esac
    
    echo ""
    echo "✅ Region configuration updated!"
    echo "New configuration:"
    echo "AWS CLI region: $(aws configure get region)"
    echo "Terraform region: $(grep -r "region.*=" terraform/provider.tf | cut -d'"' -f2)"
else
    echo "✅ Regions are already synchronized: $AWS_CLI_REGION"
fi

echo ""
echo "Important notes:"
echo "- Make sure the AMI ID in terraform/instances/variable.tf is valid for your chosen region"
echo "- Some AWS services may have different availability in different regions"
echo "- You may need to re-run 'terraform init' after changing regions"
