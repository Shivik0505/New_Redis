#!/bin/bash

set -e

echo "=== Jenkins Deployment Setup ==="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}This script prepares your Redis demo for Jenkins one-click deployment${NC}"
echo ""

# Step 1: Generate new key pair
echo -e "${YELLOW}Step 1: Generate new key pair${NC}"
read -p "Do you want to generate a new key pair? (y/N): " generate_key
if [[ $generate_key =~ ^[Yy]$ ]]; then
    ./generate-new-keypair.sh
else
    echo "Skipping key pair generation"
fi

# Step 2: Validate setup
echo ""
echo -e "${YELLOW}Step 2: Validate setup${NC}"
./validate-setup.sh

# Step 3: Check Git status
echo ""
echo -e "${YELLOW}Step 3: Git repository status${NC}"
if [ -d ".git" ]; then
    echo "Git repository detected"
    echo "Modified files:"
    git status --porcelain
    echo ""
    read -p "Do you want to commit and push changes? (y/N): " commit_changes
    if [[ $commit_changes =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "Update key pair configuration for Jenkins deployment"
        git push
        echo -e "${GREEN}✓${NC} Changes committed and pushed"
    else
        echo "⚠️  Remember to commit and push changes before running Jenkins pipeline"
    fi
else
    echo "⚠️  No Git repository found. Make sure to push changes to your Git repository."
fi

# Step 4: Jenkins instructions
echo ""
echo -e "${BLUE}=== Jenkins Pipeline Instructions ===${NC}"
echo ""
echo "Your Redis infrastructure is now ready for Jenkins one-click deployment!"
echo ""
echo -e "${GREEN}Jenkins Pipeline Parameters:${NC}"
echo "• autoApprove: true (for one-click deployment)"
echo "• action: apply (to deploy infrastructure)"
echo "• keyPairName: [your-new-key-name] (if you generated a new key)"
echo "• recreateKeyPair: false (unless you want to force recreate)"
echo ""
echo -e "${GREEN}Required Jenkins Credentials:${NC}"
echo "• AWS_ACCESS_KEY_ID: Your AWS access key"
echo "• AWS_SECRET_ACCESS_KEY: Your AWS secret key"
echo ""
echo -e "${GREEN}Pipeline Features:${NC}"
echo "✓ Automatic key pair creation/management"
echo "✓ Terraform infrastructure deployment"
echo "✓ Ansible Redis cluster configuration"
echo "✓ Deployment verification"
echo "✓ Key pair cleanup on destroy"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Ensure your Jenkins has the required AWS credentials configured"
echo "2. Run the Jenkins pipeline with autoApprove=true"
echo "3. The pipeline will handle everything automatically!"
echo ""
echo -e "${GREEN}Manual Deployment Alternative:${NC}"
echo "If you prefer manual deployment: ./deploy-infrastructure.sh"
echo ""
echo "🚀 Ready for one-click deployment!"
