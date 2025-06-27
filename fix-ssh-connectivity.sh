#!/bin/bash

# SSH Connectivity Fix Script for Jenkins Pipeline
# Fixes SSH authentication and connectivity issues

set -e

echo "🔧 SSH Connectivity Fix Script"
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Get current running instances
get_instance_info() {
    echo -e "\n${BLUE}1. Getting Current Instance Information${NC}"
    echo "======================================"
    
    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --region ap-south-1 \
        --filters "Name=tag:Name,Values=redis-public" "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].PublicIpAddress' \
        --output text)
    
    # Get private IPs
    PRIVATE_IPS=($(aws ec2 describe-instances \
        --region ap-south-1 \
        --filters "Name=tag:Name,Values=redis-private*" "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].PrivateIpAddress' \
        --output text))
    
    echo "Current running instances:"
    echo "  Bastion (Public): $PUBLIC_IP"
    echo "  Redis Node 1: ${PRIVATE_IPS[0]}"
    echo "  Redis Node 2: ${PRIVATE_IPS[1]}"
    echo "  Redis Node 3: ${PRIVATE_IPS[2]}"
    
    if [ -z "$PUBLIC_IP" ]; then
        print_status "ERROR" "No running bastion host found"
        return 1
    fi
    
    if [ ${#PRIVATE_IPS[@]} -ne 3 ]; then
        print_status "ERROR" "Expected 3 Redis nodes, found ${#PRIVATE_IPS[@]}"
        return 1
    fi
    
    print_status "SUCCESS" "All instances are running"
}

# Create fixed inventory without naming conflicts
create_fixed_inventory() {
    echo -e "\n${BLUE}2. Creating Fixed Inventory${NC}"
    echo "=========================="
    
    cat > inventory_fixed.ini << EOL
[redis_nodes]
redis-node-1 ansible_host=${PRIVATE_IPS[0]} ansible_user=ubuntu
redis-node-2 ansible_host=${PRIVATE_IPS[1]} ansible_user=ubuntu
redis-node-3 ansible_host=${PRIVATE_IPS[2]} ansible_user=ubuntu

[redis_nodes:vars]
ansible_ssh_private_key_file=./redis-infra-key.pem
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30 -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ProxyCommand="ssh -W %h:%p -i ./redis-infra-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=30 ubuntu@$PUBLIC_IP"
ansible_python_interpreter=/usr/bin/python3

[all:vars]
ansible_ssh_user=ubuntu
ansible_ssh_private_key_file=./redis-infra-key.pem
bastion_host=$PUBLIC_IP
EOL
    
    print_status "SUCCESS" "Fixed inventory created: inventory_fixed.ini"
}

# Create SSH test script
create_ssh_test() {
    echo -e "\n${BLUE}3. Creating SSH Test Script${NC}"
    echo "=========================="
    
    cat > test-ssh-connectivity.sh << 'EOF'
#!/bin/bash

echo "🔗 Testing SSH Connectivity"
echo "=========================="

# Check if key file exists and has correct permissions
if [ ! -f "redis-infra-key.pem" ]; then
    echo "❌ SSH key file not found: redis-infra-key.pem"
    exit 1
fi

# Set correct permissions
chmod 400 redis-infra-key.pem
echo "✅ SSH key permissions set to 400"

# Get current IPs
PUBLIC_IP=$(aws ec2 describe-instances \
    --region ap-south-1 \
    --filters "Name=tag:Name,Values=redis-public" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text)

PRIVATE_IPS=($(aws ec2 describe-instances \
    --region ap-south-1 \
    --filters "Name=tag:Name,Values=redis-private*" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].PrivateIpAddress' \
    --output text))

echo "Testing connectivity to:"
echo "  Bastion: $PUBLIC_IP"
echo "  Redis nodes: ${PRIVATE_IPS[@]}"

# Test direct SSH to bastion
echo ""
echo "1. Testing direct SSH to bastion host..."
if timeout 30 ssh -i redis-infra-key.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP "echo 'Bastion SSH successful'" 2>/dev/null; then
    echo "✅ Direct SSH to bastion host successful"
else
    echo "❌ Direct SSH to bastion host failed"
    echo "Debugging SSH connection..."
    ssh -i redis-infra-key.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no -v ubuntu@$PUBLIC_IP "echo 'test'" 2>&1 | head -20
    exit 1
fi

# Test SSH through bastion to private nodes
echo ""
echo "2. Testing SSH through bastion to private nodes..."
for i in "${!PRIVATE_IPS[@]}"; do
    PRIVATE_IP=${PRIVATE_IPS[$i]}
    echo "Testing connection to redis-node-$((i+1)) ($PRIVATE_IP)..."
    
    if timeout 30 ssh -i redis-infra-key.pem \
        -o ProxyCommand="ssh -W %h:%p -i redis-infra-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=30 ubuntu@$PUBLIC_IP" \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=30 \
        ubuntu@$PRIVATE_IP "echo 'Redis node SSH successful'" 2>/dev/null; then
        echo "✅ SSH to redis-node-$((i+1)) successful"
    else
        echo "❌ SSH to redis-node-$((i+1)) failed"
        echo "Debugging connection..."
        ssh -i redis-infra-key.pem \
            -o ProxyCommand="ssh -W %h:%p -i redis-infra-key.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP" \
            -o StrictHostKeyChecking=no \
            -v ubuntu@$PRIVATE_IP "echo 'test'" 2>&1 | head -10
    fi
done

echo ""
echo "3. Testing Ansible connectivity..."
if [ -f "inventory_fixed.ini" ]; then
    ansible all -i inventory_fixed.ini -m ping --timeout=30
else
    echo "❌ inventory_fixed.ini not found"
    exit 1
fi

echo "✅ SSH connectivity test completed"
EOF
    
    chmod +x test-ssh-connectivity.sh
    print_status "SUCCESS" "SSH test script created"
}

# Create improved create-inventory.sh
create_improved_inventory_script() {
    echo -e "\n${BLUE}4. Creating Improved Inventory Script${NC}"
    echo "===================================="
    
    cat > create-inventory-improved.sh << 'EOF'
#!/bin/bash

# Improved Inventory Creation Script
# Fixes naming conflicts and SSH connectivity issues

set -e

echo "🔧 Creating improved Ansible inventory..."

# Get running instances with better error handling
PUBLIC_IP=$(aws ec2 describe-instances \
    --region ap-south-1 \
    --filters "Name=tag:Name,Values=redis-public" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    echo "❌ No running bastion host found"
    exit 1
fi

PRIVATE_IPS=($(aws ec2 describe-instances \
    --region ap-south-1 \
    --filters "Name=tag:Name,Values=redis-private*" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].PrivateIpAddress' \
    --output text))

if [ ${#PRIVATE_IPS[@]} -ne 3 ]; then
    echo "❌ Expected 3 Redis nodes, found ${#PRIVATE_IPS[@]}"
    exit 1
fi

echo "Discovered instances:"
echo "  Bastion (Public): $PUBLIC_IP"
echo "  Redis Node 1: ${PRIVATE_IPS[0]}"
echo "  Redis Node 2: ${PRIVATE_IPS[1]}"
echo "  Redis Node 3: ${PRIVATE_IPS[2]}"

# Create inventory without naming conflicts
cat > inventory.ini << EOL
[redis_nodes]
redis-node-1 ansible_host=${PRIVATE_IPS[0]} ansible_user=ubuntu
redis-node-2 ansible_host=${PRIVATE_IPS[1]} ansible_user=ubuntu
redis-node-3 ansible_host=${PRIVATE_IPS[2]} ansible_user=ubuntu

[redis_nodes:vars]
ansible_ssh_private_key_file=./redis-infra-key.pem
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30 -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ProxyCommand="ssh -W %h:%p -i ./redis-infra-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=30 ubuntu@$PUBLIC_IP"
ansible_python_interpreter=/usr/bin/python3

[all:vars]
ansible_ssh_user=ubuntu
ansible_ssh_private_key_file=./redis-infra-key.pem
bastion_host=$PUBLIC_IP
EOL

echo "✅ Inventory created: inventory.ini"
echo "📋 Inventory contents:"
cat inventory.ini
EOF
    
    chmod +x create-inventory-improved.sh
    print_status "SUCCESS" "Improved inventory script created"
}

# Create SSH debugging playbook
create_debug_playbook() {
    echo -e "\n${BLUE}5. Creating SSH Debug Playbook${NC}"
    echo "============================="
    
    cat > playbook-debug.yml << 'EOF'
---
- name: SSH Connectivity Debug
  hosts: redis_nodes
  gather_facts: no
  vars:
    ansible_ssh_user: ubuntu
    ansible_ssh_private_key_file: "./redis-infra-key.pem"
    ansible_ssh_common_args: >-
      -o StrictHostKeyChecking=no
      -o UserKnownHostsFile=/dev/null
      -o ConnectTimeout=30
      -o ServerAliveInterval=60
      -o ServerAliveCountMax=3
      -o ProxyCommand="ssh -W %h:%p -i ./redis-infra-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=30 ubuntu@{{ bastion_host }}"
  
  tasks:
    - name: Test raw connection
      raw: echo "SSH connection successful"
      register: ssh_test
    
    - name: Display connection result
      debug:
        msg: "SSH connection to {{ inventory_hostname }} successful"
    
    - name: Wait for system to become reachable
      wait_for_connection:
        connect_timeout: 30
        timeout: 300
    
    - name: Gather minimal facts
      setup:
        gather_subset: min
    
    - name: Test sudo access
      become: yes
      command: whoami
      register: sudo_test
    
    - name: Display system info
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          IP: {{ ansible_host }}
          User: {{ ansible_user }}
          Sudo test: {{ sudo_test.stdout }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
EOF
    
    print_status "SUCCESS" "Debug playbook created"
}

# Create Jenkins-compatible SSH fix
create_jenkins_ssh_fix() {
    echo -e "\n${BLUE}6. Creating Jenkins SSH Fix${NC}"
    echo "=========================="
    
    cat > jenkins-ssh-fix.sh << 'EOF'
#!/bin/bash

# Jenkins SSH Fix Script
# Run this in Jenkins pipeline to fix SSH connectivity

echo "🔧 Jenkins SSH Connectivity Fix"
echo "==============================="

# Set proper SSH key permissions
if [ -f "redis-infra-key.pem" ]; then
    chmod 400 redis-infra-key.pem
    echo "✅ SSH key permissions set"
else
    echo "❌ SSH key file not found"
    exit 1
fi

# Create improved inventory
./create-inventory-improved.sh

# Test SSH connectivity
echo "Testing SSH connectivity..."
timeout 60 ./test-ssh-connectivity.sh || {
    echo "❌ SSH connectivity test failed"
    echo "Checking security groups..."
    
    # Check security groups
    aws ec2 describe-security-groups \
        --region ap-south-1 \
        --filters "Name=group-name,Values=*redis*" \
        --query 'SecurityGroups[].{GroupName:GroupName,Rules:IpPermissions[?FromPort==`22`]}' \
        --output table
    
    echo "Manual SSH test commands:"
    PUBLIC_IP=$(aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:Name,Values=redis-public" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].PublicIpAddress' --output text)
    echo "ssh -i redis-infra-key.pem ubuntu@$PUBLIC_IP"
    
    exit 1
}

echo "✅ SSH connectivity verified"
EOF
    
    chmod +x jenkins-ssh-fix.sh
    print_status "SUCCESS" "Jenkins SSH fix script created"
}

# Main execution
main() {
    echo "Starting SSH connectivity fix..."
    echo "Current directory: $(pwd)"
    echo ""
    
    local exit_code=0
    
    get_instance_info || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        create_fixed_inventory
        create_ssh_test
        create_improved_inventory_script
        create_debug_playbook
        create_jenkins_ssh_fix
        
        echo -e "\n${BLUE}📋 SSH Connectivity Fix Summary${NC}"
        echo "==============================="
        
        print_status "SUCCESS" "All SSH fixes applied successfully!"
        echo ""
        echo "✅ Files created:"
        echo "   - inventory_fixed.ini (fixed inventory without conflicts)"
        echo "   - test-ssh-connectivity.sh (comprehensive SSH testing)"
        echo "   - create-inventory-improved.sh (improved inventory creation)"
        echo "   - playbook-debug.yml (SSH debugging playbook)"
        echo "   - jenkins-ssh-fix.sh (Jenkins-specific SSH fix)"
        echo ""
        echo "🚀 Next steps:"
        echo "   1. Test SSH connectivity: ./test-ssh-connectivity.sh"
        echo "   2. Replace create-inventory.sh with create-inventory-improved.sh"
        echo "   3. Use inventory_fixed.ini for Ansible operations"
        echo "   4. Push changes to GitHub for Jenkins pipeline"
        echo ""
        echo "🔧 For Jenkins pipeline:"
        echo "   - Use jenkins-ssh-fix.sh in the Ansible stage"
        echo "   - Replace inventory creation with improved version"
        echo "   - Add SSH connectivity testing before Ansible execution"
    else
        print_status "ERROR" "Could not get instance information"
        echo "Please ensure AWS credentials are configured and instances are running"
    fi
    
    return $exit_code
}

# Run the main function
main "$@"
