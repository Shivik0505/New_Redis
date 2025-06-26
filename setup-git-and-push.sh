#!/bin/bash

set -e

echo "=== Git Setup and GitHub Push ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Setting up Redis Infrastructure project for GitHub...${NC}"

# Check if we're in a subdirectory of another git repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  This directory is part of an existing Git repository.${NC}"
    echo "We'll initialize a new repository for this Redis project."
    
    # Remove any existing git configuration
    rm -rf .git 2>/dev/null || true
fi

# Initialize new Git repository
echo -e "\n${BLUE}1. Initializing new Git repository...${NC}"
git init
echo -e "${GREEN}✓${NC} Git repository initialized"

# Add all files except those in .gitignore
echo -e "\n${BLUE}2. Adding files to Git...${NC}"
git add .
echo -e "${GREEN}✓${NC} Files added to staging"

# Check what will be committed
echo -e "\n${BLUE}Files to be committed:${NC}"
git status --short

# Create initial commit
echo -e "\n${BLUE}3. Creating initial commit...${NC}"
git commit -m "Initial commit: Redis Infrastructure with Jenkins one-click deployment

Features:
- Complete Redis cluster infrastructure with Terraform
- Automated deployment via Jenkins pipeline
- Ansible configuration for Redis clustering
- AWS key pair management
- One-click deployment capability
- Comprehensive documentation and troubleshooting guides

Infrastructure:
- Custom VPC with multi-AZ deployment
- 1 Bastion host + 3 Redis nodes
- Proper security groups and networking
- NAT Gateway for private subnet access

Tools included:
- Key pair generator and updater
- Validation and troubleshooting scripts
- Enhanced Jenkinsfile with parameter support
- Complete deployment automation"

echo -e "${GREEN}✓${NC} Initial commit created"

# Get GitHub repository URL
echo -e "\n${BLUE}4. GitHub Repository Setup${NC}"
echo "Please provide your GitHub repository details:"
echo ""
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter repository name (default: redis-infrastructure): " REPO_NAME
REPO_NAME=${REPO_NAME:-redis-infrastructure}

GITHUB_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

echo -e "\n${YELLOW}Repository URL: ${GITHUB_URL}${NC}"
echo ""
echo "Please ensure you have:"
echo "1. Created the repository '${REPO_NAME}' on GitHub"
echo "2. Have proper GitHub authentication set up (token or SSH)"
echo ""
read -p "Continue with push? (y/N): " CONTINUE_PUSH

if [[ $CONTINUE_PUSH =~ ^[Yy]$ ]]; then
    echo -e "\n${BLUE}5. Adding GitHub remote...${NC}"
    git remote add origin "$GITHUB_URL"
    echo -e "${GREEN}✓${NC} Remote added"
    
    echo -e "\n${BLUE}6. Pushing to GitHub...${NC}"
    git branch -M main
    
    # Try to push
    if git push -u origin main; then
        echo -e "\n${GREEN}🎉 Successfully pushed to GitHub!${NC}"
        echo -e "${GREEN}Repository URL: ${GITHUB_URL}${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Visit your GitHub repository to verify the upload"
        echo "2. Set up Jenkins to use this repository"
        echo "3. Configure Jenkins with your AWS credentials"
        echo "4. Run the pipeline with autoApprove=true for one-click deployment"
        echo ""
        echo -e "${GREEN}Jenkins Pipeline URL format:${NC}"
        echo "Repository URL: ${GITHUB_URL}"
        echo "Branch: main"
        echo "Script Path: Jenkinsfile"
    else
        echo -e "\n${RED}❌ Push failed!${NC}"
        echo ""
        echo "Common solutions:"
        echo "1. Make sure the repository exists on GitHub"
        echo "2. Check your GitHub authentication (token/SSH key)"
        echo "3. Verify repository permissions"
        echo ""
        echo "Manual push commands:"
        echo "git remote add origin ${GITHUB_URL}"
        echo "git branch -M main"
        echo "git push -u origin main"
    fi
else
    echo -e "\n${YELLOW}Push cancelled.${NC}"
    echo ""
    echo "To push manually later:"
    echo "1. Create repository '${REPO_NAME}' on GitHub"
    echo "2. Run: git remote add origin ${GITHUB_URL}"
    echo "3. Run: git branch -M main"
    echo "4. Run: git push -u origin main"
fi

echo -e "\n${BLUE}=== Git Setup Complete ===${NC}"
echo ""
echo "Repository status:"
git status
echo ""
echo "Recent commits:"
git log --oneline -3
