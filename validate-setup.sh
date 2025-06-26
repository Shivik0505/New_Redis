#!/bin/bash

echo "=== Redis Infrastructure Validation ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "Checking project structure and configuration..."

# Check directory structure
echo -e "\n1. Directory Structure:"
[ -d "terraform" ] && print_status 0 "terraform/ directory exists" || print_status 1 "terraform/ directory missing"
[ -d "ansible" ] && print_status 0 "ansible/ directory exists" || print_status 1 "ansible/ directory missing"
[ -f "playbook.yml" ] && print_status 0 "playbook.yml exists" || print_status 1 "playbook.yml missing"
[ -f "aws_ec2.yaml" ] && print_status 0 "aws_ec2.yaml exists" || print_status 1 "aws_ec2.yaml missing"

# Check for nested directory issue
if [ -d "Redis_demo" ]; then
    print_warning "Nested Redis_demo directory found - this may cause confusion"
    echo "  Run ./fix-directory-structure.sh to clean this up"
fi

# Check Terraform configuration
echo -e "\n2. Terraform Configuration:"
if [ -d "terraform" ]; then
    cd terraform
    
    # Check if terraform is initialized
    if [ -d ".terraform" ]; then
        print_status 0 "Terraform initialized"
    else
        print_status 1 "Terraform not initialized - run 'terraform init'"
    fi
    
    # Validate terraform configuration
    if terraform validate >/dev/null 2>&1; then
        print_status 0 "Terraform configuration valid"
    else
        print_status 1 "Terraform configuration has errors"
        echo "Run 'terraform validate' for details"
    fi
    
    # Check key pair configuration
    if [ -f "instances/variable.tf" ]; then
        KEY_NAME=$(grep -o 'default = "[^"]*"' instances/variable.tf | cut -d'"' -f2)
        echo "  Configured key pair: $KEY_NAME"
    fi
    
    cd ..
else
    print_status 1 "Cannot check Terraform - directory missing"
fi

# Check AWS CLI configuration
echo -e "\n3. AWS Configuration:"
if command -v aws >/dev/null 2>&1; then
    print_status 0 "AWS CLI installed"
    
    if aws sts get-caller-identity >/dev/null 2>&1; then
        print_status 0 "AWS credentials configured"
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
        REGION=$(aws configure get region 2>/dev/null || echo "ap-south-1")
        echo "  Account ID: $ACCOUNT_ID"
        echo "  Region: $REGION"
        
        # Check if key pair exists in AWS
        if [ ! -z "$KEY_NAME" ]; then
            if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" >/dev/null 2>&1; then
                print_status 0 "Key pair '$KEY_NAME' exists in AWS"
            else
                print_warning "Key pair '$KEY_NAME' not found in AWS region $REGION"
                echo "  Run ./generate-new-keypair.sh to create it"
            fi
        fi
    else
        print_status 1 "AWS credentials not configured or invalid"
    fi
else
    print_status 1 "AWS CLI not installed"
fi

# Check Ansible configuration
echo -e "\n4. Ansible Configuration:"
if command -v ansible >/dev/null 2>&1; then
    print_status 0 "Ansible installed"
    
    # Check ansible role structure
    if [ -d "ansible/tasks" ] && [ -f "ansible/tasks/main.yml" ]; then
        print_status 0 "Ansible role structure correct"
    else
        print_status 1 "Ansible role structure incomplete"
    fi
    
    # Check if ansible can parse inventory
    if ansible-inventory -i aws_ec2.yaml --list >/dev/null 2>&1; then
        print_status 0 "Ansible inventory configuration valid"
    else
        print_status 1 "Ansible inventory configuration has issues"
    fi
    
    # Check key configuration in Ansible files
    ANSIBLE_KEY=$(grep -o '\./[^"]*\.pem' aws_ec2.yaml 2>/dev/null | head -1 | sed 's/\.\///')
    if [ ! -z "$ANSIBLE_KEY" ]; then
        echo "  Ansible configured for key: $ANSIBLE_KEY"
    fi
else
    print_status 1 "Ansible not installed"
fi

# Check required files
echo -e "\n5. Required Files:"
[ -f "deploy-infrastructure.sh" ] && print_status 0 "deploy-infrastructure.sh exists" || print_status 1 "deploy-infrastructure.sh missing"
[ -f "cleanup-conflicts.sh" ] && print_status 0 "cleanup-conflicts.sh exists" || print_status 1 "cleanup-conflicts.sh missing"
[ -f "Jenkinsfile" ] && print_status 0 "Jenkinsfile exists" || print_status 1 "Jenkinsfile missing"
[ -f "generate-new-keypair.sh" ] && print_status 0 "generate-new-keypair.sh exists" || print_status 1 "generate-new-keypair.sh missing"

# Check script permissions
echo -e "\n6. Script Permissions:"
[ -x "deploy-infrastructure.sh" ] && print_status 0 "deploy-infrastructure.sh is executable" || print_status 1 "deploy-infrastructure.sh not executable"
[ -x "cleanup-conflicts.sh" ] && print_status 0 "cleanup-conflicts.sh is executable" || print_status 1 "cleanup-conflicts.sh not executable"
[ -x "generate-new-keypair.sh" ] && print_status 0 "generate-new-keypair.sh is executable" || print_status 1 "generate-new-keypair.sh not executable"

# Check Jenkins readiness
echo -e "\n7. Jenkins Deployment Readiness:"
if [ -f "Jenkinsfile" ]; then
    # Check if Jenkinsfile has the enhanced version
    if grep -q "keyPairName" Jenkinsfile; then
        print_status 0 "Enhanced Jenkinsfile with key pair management"
    else
        print_warning "Basic Jenkinsfile - consider updating for better key management"
    fi
    
    # Check Git status
    if [ -d ".git" ]; then
        if git status --porcelain | grep -q .; then
            print_warning "Uncommitted changes detected - commit before Jenkins deployment"
        else
            print_status 0 "Git repository clean"
        fi
    else
        print_warning "No Git repository - ensure code is in version control for Jenkins"
    fi
fi

# Summary
echo -e "\n=== Validation Summary ==="
echo "If you see any ✗ marks above, please address those issues before deployment."
echo ""
echo "Quick fixes:"
echo "- Run './generate-new-keypair.sh' to create/update key pair"
echo "- Run './fix-directory-structure.sh' to clean up nested directories"
echo "- Run 'terraform init' in the terraform/ directory"
echo "- Configure AWS CLI with 'aws configure'"
echo "- Install missing tools (terraform, ansible, aws-cli)"
echo ""
echo "For Jenkins deployment:"
echo "- Run './setup-for-jenkins.sh' for complete Jenkins setup"
echo "- Ensure Jenkins has AWS credentials configured"
echo "- Use autoApprove=true for one-click deployment"
echo ""
echo "For manual deployment:"
echo "- Run './deploy-infrastructure.sh' after fixing any issues"
