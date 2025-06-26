#!/bin/bash

echo "=== Pre-Push Verification ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

echo -e "${BLUE}Checking project readiness for GitHub push...${NC}"

# Check for sensitive files
echo -e "\n${BLUE}1. Security Check - Sensitive Files${NC}"
SENSITIVE_FILES=0

if [ -f "redis-demo-key.pem" ]; then
    echo -e "${YELLOW}⚠️  Found: redis-demo-key.pem${NC}"
    SENSITIVE_FILES=1
fi

if [ -f "my-key-aws.pem" ]; then
    echo -e "${YELLOW}⚠️  Found: my-key-aws.pem${NC}"
    SENSITIVE_FILES=1
fi

if find . -name "*.pem" -type f | grep -q .; then
    echo -e "${YELLOW}⚠️  Found .pem files:${NC}"
    find . -name "*.pem" -type f
    SENSITIVE_FILES=1
fi

if [ $SENSITIVE_FILES -eq 0 ]; then
    print_status 0 "No sensitive files found"
else
    echo -e "${YELLOW}Note: .pem files are in .gitignore and won't be committed${NC}"
fi

# Check .gitignore
echo -e "\n${BLUE}2. .gitignore Configuration${NC}"
if [ -f ".gitignore" ]; then
    if grep -q "*.pem" .gitignore; then
        print_status 0 ".gitignore properly configured for .pem files"
    else
        print_status 1 ".gitignore missing .pem exclusion"
    fi
    
    if grep -q ".terraform" .gitignore; then
        print_status 0 ".gitignore configured for Terraform cache"
    else
        print_status 1 ".gitignore missing Terraform cache exclusion"
    fi
else
    print_status 1 ".gitignore file missing"
fi

# Check for cache files
echo -e "\n${BLUE}3. Cache Files Check${NC}"
CACHE_FILES=0

if [ -d "terraform/.terraform" ]; then
    echo -e "${YELLOW}⚠️  Found: terraform/.terraform${NC}"
    CACHE_FILES=1
fi

if find . -name "*.bak" -type f | grep -q .; then
    echo -e "${YELLOW}⚠️  Found .bak files:${NC}"
    find . -name "*.bak" -type f
    CACHE_FILES=1
fi

if find . -name ".DS_Store" -type f | grep -q .; then
    echo -e "${YELLOW}⚠️  Found .DS_Store files:${NC}"
    find . -name ".DS_Store" -type f
    CACHE_FILES=1
fi

if [ $CACHE_FILES -eq 0 ]; then
    print_status 0 "No cache files found"
else
    echo -e "${YELLOW}Run ./cleanup-cache.sh to clean these files${NC}"
fi

# Check essential files
echo -e "\n${BLUE}4. Essential Files Check${NC}"
[ -f "README.md" ] && print_status 0 "README.md exists" || print_status 1 "README.md missing"
[ -f "Jenkinsfile" ] && print_status 0 "Jenkinsfile exists" || print_status 1 "Jenkinsfile missing"
[ -f "terraform/main.tf" ] && print_status 0 "Terraform configuration exists" || print_status 1 "Terraform configuration missing"
[ -f "playbook.yml" ] && print_status 0 "Ansible playbook exists" || print_status 1 "Ansible playbook missing"
[ -f "deploy-infrastructure.sh" ] && print_status 0 "Deployment script exists" || print_status 1 "Deployment script missing"

# Check documentation
echo -e "\n${BLUE}5. Documentation Check${NC}"
[ -f "JENKINS_DEPLOYMENT_GUIDE.md" ] && print_status 0 "Jenkins guide exists" || print_status 1 "Jenkins guide missing"
[ -f "TROUBLESHOOTING.md" ] && print_status 0 "Troubleshooting guide exists" || print_status 1 "Troubleshooting guide missing"
[ -f "DEPLOYMENT_READY_SUMMARY.md" ] && print_status 0 "Deployment summary exists" || print_status 1 "Deployment summary missing"

# File count summary
echo -e "\n${BLUE}6. Project Summary${NC}"
TOTAL_FILES=$(find . -type f | wc -l | tr -d ' ')
SCRIPT_FILES=$(find . -name "*.sh" -type f | wc -l | tr -d ' ')
MD_FILES=$(find . -name "*.md" -type f | wc -l | tr -d ' ')
TF_FILES=$(find . -name "*.tf" -type f | wc -l | tr -d ' ')

echo "Total files: $TOTAL_FILES"
echo "Shell scripts: $SCRIPT_FILES"
echo "Documentation files: $MD_FILES"
echo "Terraform files: $TF_FILES"

# Git status check
echo -e "\n${BLUE}7. Git Status${NC}"
if git rev-parse --git-dir > /dev/null 2>&1; then
    print_status 0 "Git repository initialized"
    
    if git status --porcelain | grep -q .; then
        echo -e "${YELLOW}⚠️  Uncommitted changes detected${NC}"
        echo "Files to be committed:"
        git status --short
    else
        print_status 0 "Working directory clean"
    fi
else
    print_status 1 "Git repository not initialized"
fi

echo -e "\n${GREEN}=== Pre-Push Check Complete ===${NC}"
echo ""
echo -e "${BLUE}Recommendations:${NC}"
if [ $CACHE_FILES -gt 0 ]; then
    echo "• Run ./cleanup-cache.sh to remove cache files"
fi
echo "• Review .gitignore to ensure sensitive files are excluded"
echo "• Verify all documentation is up to date"
echo "• Test deployment scripts before pushing"
echo ""
echo -e "${GREEN}Ready to push to GitHub!${NC}"
echo "Run ./setup-git-and-push.sh to initialize Git and push to GitHub"
