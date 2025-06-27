#!/bin/bash

# Jenkins Pipeline Troubleshooting Script
# This script helps diagnose and fix common Jenkins pipeline issues

set -e

echo "🔧 Jenkins Pipeline Troubleshooting Script"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

# Check AWS CLI configuration
check_aws_cli() {
    echo -e "\n${BLUE}1. Checking AWS CLI Configuration${NC}"
    echo "=================================="
    
    if command -v aws &> /dev/null; then
        print_status "SUCCESS" "AWS CLI is installed"
        aws --version
        
        if aws sts get-caller-identity &> /dev/null; then
            print_status "SUCCESS" "AWS credentials are configured and valid"
            aws sts get-caller-identity
        else
            print_status "ERROR" "AWS credentials are not configured or invalid"
            echo "Fix: Configure AWS credentials using 'aws configure' or set environment variables"
            return 1
        fi
    else
        print_status "ERROR" "AWS CLI is not installed"
        echo "Fix: Install AWS CLI - https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        return 1
    fi
}

# Check Terraform installation
check_terraform() {
    echo -e "\n${BLUE}2. Checking Terraform Installation${NC}"
    echo "=================================="
    
    if command -v terraform &> /dev/null; then
        print_status "SUCCESS" "Terraform is installed"
        terraform version
        
        # Check if terraform directory exists and is properly configured
        if [ -d "terraform" ]; then
            print_status "SUCCESS" "Terraform directory found"
            
            cd terraform
            if terraform init -backend=false &> /dev/null; then
                print_status "SUCCESS" "Terraform configuration is valid"
            else
                print_status "ERROR" "Terraform configuration has issues"
                echo "Fix: Check terraform configuration files for syntax errors"
                cd ..
                return 1
            fi
            cd ..
        else
            print_status "ERROR" "Terraform directory not found"
            return 1
        fi
    else
        print_status "ERROR" "Terraform is not installed"
        echo "Fix: Install Terraform - https://learn.hashicorp.com/tutorials/terraform/install-cli"
        return 1
    fi
}

# Check Ansible installation
check_ansible() {
    echo -e "\n${BLUE}3. Checking Ansible Installation${NC}"
    echo "================================"
    
    if command -v ansible &> /dev/null; then
        print_status "SUCCESS" "Ansible is installed"
        ansible --version
        
        # Check ansible configuration
        if [ -f "ansible.cfg" ]; then
            print_status "SUCCESS" "Ansible configuration file found"
        else
            print_status "WARNING" "Ansible configuration file not found"
        fi
        
        if [ -f "playbook.yml" ]; then
            print_status "SUCCESS" "Ansible playbook found"
        else
            print_status "WARNING" "Ansible playbook not found"
        fi
    else
        print_status "ERROR" "Ansible is not installed"
        echo "Fix: Install Ansible - https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
        return 1
    fi
}

# Check AWS service limits
check_aws_limits() {
    echo -e "\n${BLUE}4. Checking AWS Service Limits${NC}"
    echo "==============================="
    
    local region=${AWS_DEFAULT_REGION:-ap-south-1}
    
    print_status "INFO" "Checking service limits in region: $region"
    
    # Check VPC limit
    local vpc_count=$(aws ec2 describe-vpcs --region $region --query 'length(Vpcs)' --output text 2>/dev/null || echo "0")
    print_status "INFO" "Current VPCs: $vpc_count/5 (default limit)"
    
    # Check Elastic IP limit
    local eip_count=$(aws ec2 describe-addresses --region $region --query 'length(Addresses)' --output text 2>/dev/null || echo "0")
    print_status "INFO" "Current Elastic IPs: $eip_count/5 (default limit)"
    
    # Check running instances
    local instance_count=$(aws ec2 describe-instances --region $region --filters "Name=instance-state-name,Values=running" --query 'length(Reservations[].Instances[])' --output text 2>/dev/null || echo "0")
    print_status "INFO" "Current running instances: $instance_count"
    
    # Check for existing Redis resources
    local redis_instances=$(aws ec2 describe-instances --region $region --filters "Name=tag:Name,Values=redis-*" --query 'length(Reservations[].Instances[])' --output text 2>/dev/null || echo "0")
    if [ "$redis_instances" -gt 0 ]; then
        print_status "WARNING" "Found $redis_instances existing Redis instances"
        echo "These might conflict with new deployment. Consider cleaning up first."
    fi
}

# Check Jenkins credentials
check_jenkins_credentials() {
    echo -e "\n${BLUE}5. Jenkins Credentials Check${NC}"
    echo "============================"
    
    if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
        print_status "SUCCESS" "AWS credentials are available as environment variables"
    else
        print_status "WARNING" "AWS credentials not found in environment variables"
        echo "In Jenkins, ensure you have configured:"
        echo "  - AWS_ACCESS_KEY_ID (String credential)"
        echo "  - AWS_SECRET_ACCESS_KEY (String credential)"
    fi
}

# Check for common file issues
check_file_permissions() {
    echo -e "\n${BLUE}6. Checking File Permissions${NC}"
    echo "============================"
    
    # Check for .pem files
    local pem_files=$(find . -name "*.pem" 2>/dev/null || true)
    if [ -n "$pem_files" ]; then
        for pem_file in $pem_files; do
            local perms=$(stat -c "%a" "$pem_file" 2>/dev/null || stat -f "%A" "$pem_file" 2>/dev/null || echo "unknown")
            if [ "$perms" = "400" ]; then
                print_status "SUCCESS" "$pem_file has correct permissions (400)"
            else
                print_status "WARNING" "$pem_file has permissions $perms (should be 400)"
                echo "Fix: chmod 400 $pem_file"
            fi
        done
    else
        print_status "INFO" "No .pem files found"
    fi
    
    # Check script permissions
    local scripts=("deploy-infrastructure.sh" "cleanup-aws-resources.sh" "quick-cleanup.sh")
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                print_status "SUCCESS" "$script is executable"
            else
                print_status "WARNING" "$script is not executable"
                echo "Fix: chmod +x $script"
            fi
        fi
    done
}

# Clean up problematic resources
cleanup_resources() {
    echo -e "\n${BLUE}7. Resource Cleanup Options${NC}"
    echo "==========================="
    
    local region=${AWS_DEFAULT_REGION:-ap-south-1}
    
    print_status "INFO" "Available cleanup options:"
    echo "1. Clean up unused VPCs: ./quick-cleanup.sh"
    echo "2. Full resource cleanup: ./cleanup-aws-resources.sh"
    echo "3. Terraform destroy: cd terraform && terraform destroy"
    
    # Check for terraform state
    if [ -f "terraform/terraform.tfstate" ]; then
        print_status "INFO" "Terraform state file found"
        echo "You can check current state with: cd terraform && terraform show"
    fi
}

# Generate Jenkins pipeline fix suggestions
generate_fixes() {
    echo -e "\n${BLUE}8. Common Pipeline Fixes${NC}"
    echo "========================"
    
    echo "If your Jenkins pipeline is failing, try these fixes:"
    echo ""
    echo "🔧 Credential Issues:"
    echo "   - Verify AWS credentials in Jenkins: Manage Jenkins > Credentials"
    echo "   - Ensure credential IDs match: 'AWS_ACCESS_KEY_ID' and 'AWS_SECRET_ACCESS_KEY'"
    echo "   - Test credentials: aws sts get-caller-identity"
    echo ""
    echo "🔧 Tool Path Issues:"
    echo "   - Add tool paths to Jenkins PATH: /usr/local/bin:/opt/homebrew/bin"
    echo "   - Install tools in Jenkins agent: terraform, aws-cli, ansible"
    echo ""
    echo "🔧 Permission Issues:"
    echo "   - Ensure Jenkins user has write permissions to workspace"
    echo "   - Check .pem file permissions: chmod 400 *.pem"
    echo ""
    echo "🔧 Resource Conflicts:"
    echo "   - Clean up existing resources before deployment"
    echo "   - Use unique names for resources"
    echo "   - Check AWS service limits"
    echo ""
    echo "🔧 Network Issues:"
    echo "   - Verify Jenkins can reach AWS APIs"
    echo "   - Check security groups and firewall rules"
    echo "   - Ensure proper VPC configuration"
}

# Main execution
main() {
    echo "Starting comprehensive Jenkins pipeline troubleshooting..."
    echo "Current directory: $(pwd)"
    echo "Current user: $(whoami)"
    echo "Date: $(date)"
    echo ""
    
    local exit_code=0
    
    check_aws_cli || exit_code=1
    check_terraform || exit_code=1
    check_ansible || exit_code=1
    check_aws_limits
    check_jenkins_credentials
    check_file_permissions
    cleanup_resources
    generate_fixes
    
    echo -e "\n${BLUE}Summary${NC}"
    echo "======="
    
    if [ $exit_code -eq 0 ]; then
        print_status "SUCCESS" "All critical checks passed!"
        echo "Your environment appears to be properly configured for Jenkins pipeline execution."
    else
        print_status "WARNING" "Some issues were found"
        echo "Please address the issues mentioned above before running the Jenkins pipeline."
    fi
    
    echo ""
    echo "📝 Next Steps:"
    echo "1. Fix any issues identified above"
    echo "2. Use the improved Jenkinsfile_Fixed for your pipeline"
    echo "3. Test the pipeline with a small deployment first"
    echo "4. Monitor Jenkins logs for any additional issues"
    
    return $exit_code
}

# Run the main function
main "$@"
