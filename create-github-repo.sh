#!/bin/bash

echo "=== GitHub Repository Creation Guide ==="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Creating GitHub repository for Shivik0505/redis-infrastructure-demo${NC}"
echo ""

echo -e "${YELLOW}Option 1: Create via GitHub Web Interface${NC}"
echo "1. Go to: https://github.com/new"
echo "2. Repository name: redis-infrastructure-demo"
echo "3. Description: Redis Infrastructure with Jenkins One-Click Deployment"
echo "4. Visibility: Public (recommended) or Private"
echo "5. ❌ DO NOT initialize with README, .gitignore, or license"
echo "6. Click 'Create repository'"
echo ""

echo -e "${YELLOW}Option 2: Create via GitHub CLI (if installed)${NC}"
echo "gh repo create redis-infrastructure-demo --public --description \"Redis Infrastructure with Jenkins One-Click Deployment\""
echo ""

echo -e "${YELLOW}Option 3: Create via API (using curl)${NC}"
echo "You'll need a GitHub Personal Access Token for this option."
echo ""

# Check if GitHub CLI is available
if command -v gh >/dev/null 2>&1; then
    echo -e "${GREEN}✓ GitHub CLI detected!${NC}"
    echo ""
    read -p "Do you want to create the repository using GitHub CLI? (y/N): " use_gh_cli
    
    if [[ $use_gh_cli =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Creating repository with GitHub CLI...${NC}"
        
        if gh repo create redis-infrastructure-demo --public --description "Redis Infrastructure with Jenkins One-Click Deployment - Complete automation with Terraform, Ansible, and Jenkins pipeline for AWS Redis cluster deployment"; then
            echo -e "${GREEN}✓ Repository created successfully!${NC}"
            
            echo -e "\n${BLUE}Pushing code to GitHub...${NC}"
            if git push -u origin main; then
                echo -e "\n${GREEN}🎉 SUCCESS! Your code has been pushed to GitHub!${NC}"
                echo -e "${GREEN}Repository URL: https://github.com/Shivik0505/redis-infrastructure-demo${NC}"
                echo ""
                echo -e "${BLUE}Next steps:${NC}"
                echo "1. Visit: https://github.com/Shivik0505/redis-infrastructure-demo"
                echo "2. Set up Jenkins with this repository"
                echo "3. Configure AWS credentials in Jenkins"
                echo "4. Run pipeline with autoApprove=true for one-click deployment"
                echo ""
                echo -e "${GREEN}🚀 Your Redis Infrastructure is ready for Jenkins deployment!${NC}"
            else
                echo -e "${RED}❌ Push failed. Please check your GitHub authentication.${NC}"
            fi
        else
            echo -e "${RED}❌ Failed to create repository. Please check your GitHub CLI authentication.${NC}"
            echo "Try: gh auth login"
        fi
    else
        echo -e "${YELLOW}Please create the repository manually using Option 1 above.${NC}"
    fi
else
    echo -e "${YELLOW}GitHub CLI not found. Please use Option 1 (web interface) to create the repository.${NC}"
fi

echo ""
echo -e "${BLUE}After creating the repository, run:${NC}"
echo "git push -u origin main"
echo ""
echo -e "${BLUE}Repository Details:${NC}"
echo "• Username: Shivik0505"
echo "• Repository: redis-infrastructure-demo"
echo "• URL: https://github.com/Shivik0505/redis-infrastructure-demo"
echo "• Branch: main"
echo "• Files ready: 60 files committed and ready to push"
