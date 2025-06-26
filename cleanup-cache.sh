#!/bin/bash

echo "=== Cleaning Cache and Unnecessary Files ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to safely remove files/directories
safe_remove() {
    if [ -e "$1" ]; then
        echo -e "${YELLOW}Removing:${NC} $1"
        rm -rf "$1"
        echo -e "${GREEN}✓${NC} Removed"
    fi
}

echo -e "${BLUE}Cleaning Terraform cache and state files...${NC}"
safe_remove "./terraform/.terraform"
safe_remove "./terraform/.terraform.lock.hcl"
safe_remove "./terraform/terraform.tfstate"
safe_remove "./terraform/terraform.tfstate.backup"
safe_remove "./terraform/tfplan"

echo -e "\n${BLUE}Cleaning backup files...${NC}"
find . -name "*.bak" -type f | while read file; do
    safe_remove "$file"
done

echo -e "\n${BLUE}Cleaning system cache files...${NC}"
find . -name ".DS_Store" -type f | while read file; do
    safe_remove "$file"
done

echo -e "\n${BLUE}Cleaning backup nested directory...${NC}"
safe_remove "./backup_nested_dir"

echo -e "\n${BLUE}Cleaning temporary files...${NC}"
find . -name "*.tmp" -type f | while read file; do
    safe_remove "$file"
done
find . -name "*.log" -type f | while read file; do
    safe_remove "$file"
done

echo -e "\n${BLUE}Cleaning old key files (keeping current one)...${NC}"
find . -name "my-key-aws.pem*" -type f | while read file; do
    safe_remove "$file"
done

echo -e "\n${BLUE}Cleaning Node.js cache (if any)...${NC}"
safe_remove "./node_modules"
safe_remove "./package-lock.json"

echo -e "\n${BLUE}Cleaning Python cache (if any)...${NC}"
find . -name "__pycache__" -type d | while read dir; do
    safe_remove "$dir"
done
find . -name "*.pyc" -type f | while read file; do
    safe_remove "$file"
done

echo -e "\n${BLUE}Cleaning Ansible cache...${NC}"
safe_remove "./.ansible"
safe_remove "./ansible.log"

echo -e "\n${GREEN}=== Cache Cleanup Complete! ===${NC}"
echo ""
echo "Files cleaned:"
echo "• Terraform state and cache files"
echo "• Backup files (.bak)"
echo "• System files (.DS_Store)"
echo "• Temporary and log files"
echo "• Old key pair files"
echo "• Nested directory backup"
echo ""
echo -e "${YELLOW}Note: Current key file 'redis-demo-key.pem' is preserved${NC}"
