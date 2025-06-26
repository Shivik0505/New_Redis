#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== AWS Key Pair Generator and Configuration Updater ===${NC}"

# Get current region from AWS CLI or use default
REGION=$(aws configure get region 2>/dev/null || echo "ap-south-1")
echo -e "Using AWS region: ${GREEN}$REGION${NC}"

# Prompt for key pair name
echo ""
echo "Current key pair name in configuration: my-key-aws"
read -p "Enter new key pair name (or press Enter to use 'redis-demo-key'): " NEW_KEY_NAME
NEW_KEY_NAME=${NEW_KEY_NAME:-redis-demo-key}

echo -e "New key pair name: ${GREEN}$NEW_KEY_NAME${NC}"

# Check if key pair already exists
echo ""
echo "Checking if key pair '$NEW_KEY_NAME' already exists..."
if aws ec2 describe-key-pairs --key-names "$NEW_KEY_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Key pair '$NEW_KEY_NAME' already exists in AWS.${NC}"
    read -p "Do you want to delete and recreate it? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo "Deleting existing key pair..."
        aws ec2 delete-key-pair --key-name "$NEW_KEY_NAME" --region "$REGION"
        echo -e "${GREEN}✓${NC} Existing key pair deleted"
    else
        echo "Keeping existing key pair. Will only update configuration files."
        SKIP_KEY_CREATION=true
    fi
fi

# Create new key pair if needed
if [ "$SKIP_KEY_CREATION" != "true" ]; then
    echo ""
    echo "Creating new key pair '$NEW_KEY_NAME'..."
    aws ec2 create-key-pair \
        --key-name "$NEW_KEY_NAME" \
        --region "$REGION" \
        --query 'KeyMaterial' \
        --output text > "${NEW_KEY_NAME}.pem"
    
    chmod 400 "${NEW_KEY_NAME}.pem"
    echo -e "${GREEN}✓${NC} Key pair created and saved as ${NEW_KEY_NAME}.pem"
    
    # Backup old key file if it exists
    if [ -f "my-key-aws.pem" ]; then
        mv my-key-aws.pem "my-key-aws.pem.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}ℹ${NC} Old key file backed up"
    fi
fi

# Update Terraform configuration
echo ""
echo "Updating Terraform configuration..."

# Update instances/variable.tf
if [ -f "terraform/instances/variable.tf" ]; then
    sed -i.bak "s/default = \".*\"/default = \"$NEW_KEY_NAME\"/" terraform/instances/variable.tf
    echo -e "${GREEN}✓${NC} Updated terraform/instances/variable.tf"
else
    echo -e "${RED}✗${NC} terraform/instances/variable.tf not found"
fi

# Update Jenkinsfile
echo "Updating Jenkinsfile..."
sed -i.bak "s/my-key-aws/$NEW_KEY_NAME/g" Jenkinsfile
echo -e "${GREEN}✓${NC} Updated Jenkinsfile"

# Update deployment script
echo "Updating deploy-infrastructure.sh..."
sed -i.bak "s/my-key-aws/$NEW_KEY_NAME/g" deploy-infrastructure.sh
echo -e "${GREEN}✓${NC} Updated deploy-infrastructure.sh"

# Update cleanup scripts
if [ -f "cleanup-conflicts.sh" ]; then
    sed -i.bak "s/my-key-aws/$NEW_KEY_NAME/g" cleanup-conflicts.sh
    echo -e "${GREEN}✓${NC} Updated cleanup-conflicts.sh"
fi

# Update Ansible configuration
echo "Updating Ansible configuration..."
sed -i.bak "s/my-key-aws/$NEW_KEY_NAME/g" aws_ec2.yaml
sed -i.bak "s/my-key-aws/$NEW_KEY_NAME/g" playbook.yml
echo -e "${GREEN}✓${NC} Updated Ansible configuration files"

# Update any other scripts that might reference the old key
find . -name "*.sh" -type f -exec grep -l "my-key-aws" {} \; | while read file; do
    if [[ "$file" != "./generate-new-keypair.sh" ]]; then
        sed -i.bak "s/my-key-aws/$NEW_KEY_NAME/g" "$file"
        echo -e "${GREEN}✓${NC} Updated $file"
    fi
done

# Create a summary file
cat > KEY_PAIR_UPDATE_SUMMARY.md << EOF
# Key Pair Update Summary

## Changes Made
- **Old Key Name**: my-key-aws
- **New Key Name**: $NEW_KEY_NAME
- **Region**: $REGION
- **Date**: $(date)

## Files Updated
- terraform/instances/variable.tf
- Jenkinsfile
- deploy-infrastructure.sh
- cleanup-conflicts.sh (if exists)
- aws_ec2.yaml
- playbook.yml
- All shell scripts containing the old key name

## New Key File
- **Location**: ${NEW_KEY_NAME}.pem
- **Permissions**: 400 (read-only for owner)

## Backup Files Created
All modified files have .bak backups created automatically.

## Next Steps for Jenkins Deployment
1. Commit and push changes to your Git repository
2. Run Jenkins pipeline with autoApprove=true
3. The pipeline will use the new key pair automatically

## Manual Deployment
If deploying manually:
\`\`\`bash
./deploy-infrastructure.sh
ansible-playbook -i aws_ec2.yaml playbook.yml --private-key=${NEW_KEY_NAME}.pem
\`\`\`

## Verification
To verify the key pair exists in AWS:
\`\`\`bash
aws ec2 describe-key-pairs --key-names $NEW_KEY_NAME --region $REGION
\`\`\`
EOF

echo ""
echo -e "${GREEN}=== Update Complete! ===${NC}"
echo ""
echo "Summary:"
echo -e "• New key pair: ${GREEN}$NEW_KEY_NAME${NC}"
echo -e "• Key file: ${GREEN}${NEW_KEY_NAME}.pem${NC}"
echo -e "• Region: ${GREEN}$REGION${NC}"
echo ""
echo "Files updated:"
echo "• Terraform configuration"
echo "• Jenkinsfile"
echo "• Deployment scripts"
echo "• Ansible configuration"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the changes in KEY_PAIR_UPDATE_SUMMARY.md"
echo "2. Test the configuration: ./validate-setup.sh"
echo "3. Commit and push to Git for Jenkins deployment"
echo "4. Or run locally: ./deploy-infrastructure.sh"
echo ""
echo -e "${YELLOW}⚠️  Important: Keep your ${NEW_KEY_NAME}.pem file secure and don't commit it to Git!${NC}"
