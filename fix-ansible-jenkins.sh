#!/bin/bash

# Ansible Jenkins Pipeline Fix Script
# This script fixes common Ansible issues in Jenkins SCM polling pipeline

set -e

echo "🔧 Ansible Jenkins Pipeline Fix Script"
echo "======================================"

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

# Check current Ansible configuration
check_ansible_config() {
    echo -e "\n${BLUE}1. Checking Current Ansible Configuration${NC}"
    echo "=========================================="
    
    if [ -f "ansible.cfg" ]; then
        print_status "SUCCESS" "ansible.cfg found"
        echo "Current configuration:"
        cat ansible.cfg
    else
        print_status "ERROR" "ansible.cfg not found"
        return 1
    fi
    
    if [ -f "playbook.yml" ]; then
        print_status "SUCCESS" "playbook.yml found"
        echo "Current playbook:"
        cat playbook.yml
    else
        print_status "ERROR" "playbook.yml not found"
        return 1
    fi
    
    if [ -f "aws_ec2.yaml" ]; then
        print_status "SUCCESS" "aws_ec2.yaml inventory found"
    else
        print_status "ERROR" "aws_ec2.yaml inventory not found"
        return 1
    fi
}

# Fix Ansible role structure
fix_ansible_roles() {
    echo -e "\n${BLUE}2. Fixing Ansible Role Structure${NC}"
    echo "================================="
    
    # Check if ansible role directory exists
    if [ ! -d "ansible" ]; then
        print_status "ERROR" "Ansible role directory not found"
        return 1
    fi
    
    # Create proper role structure
    mkdir -p ansible/roles/redis/{tasks,handlers,templates,vars,defaults,meta}
    
    # Move existing files to proper locations
    if [ -f "ansible/tasks/main.yml" ]; then
        mv ansible/tasks/main.yml ansible/roles/redis/tasks/main.yml
        print_status "SUCCESS" "Moved tasks to proper role structure"
    fi
    
    if [ -f "ansible/handlers/main.yml" ]; then
        mv ansible/handlers/main.yml ansible/roles/redis/handlers/main.yml
        print_status "SUCCESS" "Moved handlers to proper role structure"
    fi
    
    if [ -f "ansible/templates/redis.conf.j2" ]; then
        mv ansible/templates/redis.conf.j2 ansible/roles/redis/templates/redis.conf.j2
        print_status "SUCCESS" "Moved templates to proper role structure"
    fi
    
    if [ -f "ansible/vars/main.yml" ]; then
        mv ansible/vars/main.yml ansible/roles/redis/vars/main.yml
        print_status "SUCCESS" "Moved vars to proper role structure"
    fi
    
    # Clean up old directories
    rmdir ansible/tasks ansible/handlers ansible/templates ansible/vars 2>/dev/null || true
}

# Create fixed playbook
create_fixed_playbook() {
    echo -e "\n${BLUE}3. Creating Fixed Playbook${NC}"
    echo "=========================="
    
    cat > playbook_fixed.yml << 'EOF'
---
- name: Configure Redis Cluster
  hosts: all
  become: yes
  gather_facts: yes
  vars:
    ansible_ssh_user: ubuntu
    ansible_ssh_private_key_file: "{{ ssh_key_file | default('./redis-infra-key.pem') }}"
    ansible_ssh_common_args: >-
      -o StrictHostKeyChecking=no
      -o UserKnownHostsFile=/dev/null
      -o ConnectTimeout=30
      -o ServerAliveInterval=60
      -o ServerAliveCountMax=3
      {% if bastion_host is defined %}
      -o ProxyCommand="ssh -W %h:%p -i {{ ansible_ssh_private_key_file }} -o StrictHostKeyChecking=no ubuntu@{{ bastion_host }}"
      {% endif %}
  
  pre_tasks:
    - name: Wait for system to become reachable
      wait_for_connection:
        connect_timeout: 20
        sleep: 5
        delay: 5
        timeout: 300
    
    - name: Gather facts
      setup:
    
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
      retries: 3
      delay: 10
  
  tasks:
    - name: Install required packages
      apt:
        name:
          - redis-server
          - redis-tools
          - python3-pip
        state: present
        update_cache: yes
      retries: 3
      delay: 10
    
    - name: Install redis-py for Ansible redis modules
      pip:
        name: redis
        state: present
    
    - name: Stop Redis service for configuration
      service:
        name: redis-server
        state: stopped
    
    - name: Backup original Redis configuration
      copy:
        src: /etc/redis/redis.conf
        dest: /etc/redis/redis.conf.backup
        remote_src: yes
        backup: yes
    
    - name: Configure Redis for clustering
      lineinfile:
        path: /etc/redis/redis.conf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        backup: yes
      loop:
        - { regexp: '^bind ', line: 'bind 0.0.0.0' }
        - { regexp: '^# cluster-enabled ', line: 'cluster-enabled yes' }
        - { regexp: '^# cluster-config-file ', line: 'cluster-config-file nodes-6379.conf' }
        - { regexp: '^# cluster-node-timeout ', line: 'cluster-node-timeout 15000' }
        - { regexp: '^appendonly ', line: 'appendonly yes' }
        - { regexp: '^protected-mode ', line: 'protected-mode no' }
      notify: restart redis
    
    - name: Set Redis to listen on all interfaces
      lineinfile:
        path: /etc/redis/redis.conf
        regexp: '^bind 127.0.0.1'
        line: 'bind 0.0.0.0'
        backup: yes
      notify: restart redis
    
    - name: Create Redis log directory
      file:
        path: /var/log/redis
        state: directory
        owner: redis
        group: redis
        mode: '0755'
    
    - name: Start and enable Redis service
      service:
        name: redis-server
        state: started
        enabled: yes
    
    - name: Wait for Redis to be ready
      wait_for:
        port: 6379
        host: "{{ ansible_default_ipv4.address }}"
        delay: 5
        timeout: 60
    
    - name: Test Redis connectivity
      command: redis-cli -h {{ ansible_default_ipv4.address }} ping
      register: redis_ping
      retries: 5
      delay: 3
      until: redis_ping.stdout == "PONG"
    
    - name: Display Redis status
      debug:
        msg: "Redis is running on {{ ansible_default_ipv4.address }}:6379"
  
  handlers:
    - name: restart redis
      service:
        name: redis-server
        state: restarted
      listen: restart redis
EOF
    
    print_status "SUCCESS" "Fixed playbook created: playbook_fixed.yml"
}

# Create dynamic inventory script
create_dynamic_inventory() {
    echo -e "\n${BLUE}4. Creating Dynamic Inventory Script${NC}"
    echo "===================================="
    
    cat > create_dynamic_inventory.sh << 'EOF'
#!/bin/bash

# Dynamic Inventory Creation Script for Jenkins
# Creates Ansible inventory from Terraform outputs

set -e

echo "Creating dynamic Ansible inventory..."

# Get Terraform outputs
if [ -f "terraform-outputs.json" ]; then
    echo "Using existing terraform-outputs.json"
else
    echo "Generating Terraform outputs..."
    cd terraform
    terraform output -json > ../terraform-outputs.json
    cd ..
fi

# Extract IPs from Terraform outputs
PUBLIC_IP=$(jq -r '.["public-instance-ip"].value' terraform-outputs.json 2>/dev/null || echo "")
PRIVATE_IP_1=$(jq -r '.["private-instance1-ip"].value' terraform-outputs.json 2>/dev/null || echo "")
PRIVATE_IP_2=$(jq -r '.["private-instance2-ip"].value' terraform-outputs.json 2>/dev/null || echo "")
PRIVATE_IP_3=$(jq -r '.["private-instance3-ip"].value' terraform-outputs.json 2>/dev/null || echo "")

# Fallback to AWS CLI if Terraform outputs not available
if [ -z "$PUBLIC_IP" ] || [ -z "$PRIVATE_IP_1" ]; then
    echo "Terraform outputs not available, using AWS CLI..."
    
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
    
    PRIVATE_IP_1=${PRIVATE_IPS[0]}
    PRIVATE_IP_2=${PRIVATE_IPS[1]}
    PRIVATE_IP_3=${PRIVATE_IPS[2]}
fi

echo "Discovered IPs:"
echo "  Bastion (Public): $PUBLIC_IP"
echo "  Redis Node 1: $PRIVATE_IP_1"
echo "  Redis Node 2: $PRIVATE_IP_2"
echo "  Redis Node 3: $PRIVATE_IP_3"

# Create inventory file
cat > inventory_dynamic.ini << EOL
[bastion]
bastion ansible_host=$PUBLIC_IP ansible_user=ubuntu

[redis_nodes]
redis-node-1 ansible_host=$PRIVATE_IP_1 ansible_user=ubuntu
redis-node-2 ansible_host=$PRIVATE_IP_2 ansible_user=ubuntu
redis-node-3 ansible_host=$PRIVATE_IP_3 ansible_user=ubuntu

[redis_nodes:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -i ./redis-infra-key.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP"

[all:vars]
ansible_ssh_private_key_file=./redis-infra-key.pem
ansible_ssh_user=ubuntu
ansible_python_interpreter=/usr/bin/python3
EOL

echo "✅ Dynamic inventory created: inventory_dynamic.ini"
EOF
    
    chmod +x create_dynamic_inventory.sh
    print_status "SUCCESS" "Dynamic inventory script created"
}

# Create Ansible test script
create_ansible_test() {
    echo -e "\n${BLUE}5. Creating Ansible Test Script${NC}"
    echo "==============================="
    
    cat > test_ansible_connection.sh << 'EOF'
#!/bin/bash

# Ansible Connection Test Script
# Tests connectivity to all Redis nodes

set -e

echo "🧪 Testing Ansible Connectivity"
echo "==============================="

# Check if key file exists
if [ ! -f "redis-infra-key.pem" ]; then
    echo "❌ SSH key file not found: redis-infra-key.pem"
    exit 1
fi

# Set proper permissions
chmod 400 redis-infra-key.pem

# Create dynamic inventory
if [ -f "create_dynamic_inventory.sh" ]; then
    echo "📋 Creating dynamic inventory..."
    ./create_dynamic_inventory.sh
else
    echo "⚠️ Dynamic inventory script not found, using existing inventory"
fi

# Test connectivity
echo "🔗 Testing connectivity to all hosts..."

if [ -f "inventory_dynamic.ini" ]; then
    INVENTORY="inventory_dynamic.ini"
elif [ -f "aws_ec2.yaml" ]; then
    INVENTORY="aws_ec2.yaml"
else
    echo "❌ No inventory file found"
    exit 1
fi

echo "Using inventory: $INVENTORY"

# Test ping to all hosts
echo "Testing ping connectivity..."
ansible all -i $INVENTORY -m ping --timeout=30 || {
    echo "❌ Ping test failed"
    echo "Debugging connection issues..."
    
    # Debug bastion connectivity
    if [ -f "inventory_dynamic.ini" ]; then
        BASTION_IP=$(grep "bastion ansible_host=" inventory_dynamic.ini | cut -d'=' -f2 | cut -d' ' -f1)
        echo "Testing direct SSH to bastion: $BASTION_IP"
        ssh -i redis-infra-key.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$BASTION_IP "echo 'Bastion SSH OK'" || echo "❌ Bastion SSH failed"
    fi
    
    exit 1
}

echo "✅ Ansible connectivity test passed!"

# Test gathering facts
echo "🔍 Testing fact gathering..."
ansible all -i $INVENTORY -m setup -a "filter=ansible_default_ipv4" --timeout=30 || {
    echo "⚠️ Fact gathering failed, but connectivity works"
}

echo "✅ Ansible connection test completed successfully!"
EOF
    
    chmod +x test_ansible_connection.sh
    print_status "SUCCESS" "Ansible test script created"
}

# Create Jenkins-compatible Ansible configuration
create_jenkins_ansible_config() {
    echo -e "\n${BLUE}6. Creating Jenkins-Compatible Ansible Config${NC}"
    echo "=============================================="
    
    cat > ansible_jenkins.cfg << 'EOF'
[defaults]
host_key_checking = False
remote_user = ubuntu
private_key_file = ./redis-infra-key.pem
timeout = 60
gathering = smart
fact_caching = memory
stdout_callback = yaml
callback_whitelist = timer, profile_tasks
retry_files_enabled = False
log_path = ./ansible.log
force_valid_group_names = ignore

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=300s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30 -o ServerAliveInterval=60 -o ServerAliveCountMax=3
pipelining = True
control_path = ~/.ansible/cp/%%h-%%p-%%r
retries = 3

[inventory]
enable_plugins = aws_ec2, ini
cache = True
cache_plugin = memory
cache_timeout = 3600
EOF
    
    print_status "SUCCESS" "Jenkins-compatible Ansible config created: ansible_jenkins.cfg"
}

# Main execution
main() {
    echo "Starting Ansible Jenkins pipeline fix..."
    echo "Current directory: $(pwd)"
    echo "Current time: $(date)"
    echo ""
    
    local exit_code=0
    
    check_ansible_config || exit_code=1
    fix_ansible_roles
    create_fixed_playbook
    create_dynamic_inventory
    create_ansible_test
    create_jenkins_ansible_config
    
    echo -e "\n${BLUE}📋 Summary of Fixes Applied${NC}"
    echo "=========================="
    
    if [ $exit_code -eq 0 ]; then
        print_status "SUCCESS" "All Ansible fixes applied successfully!"
        echo ""
        echo "✅ Files created/updated:"
        echo "   - playbook_fixed.yml (improved playbook)"
        echo "   - create_dynamic_inventory.sh (dynamic inventory)"
        echo "   - test_ansible_connection.sh (connection testing)"
        echo "   - ansible_jenkins.cfg (Jenkins-compatible config)"
        echo ""
        echo "🚀 Next steps for Jenkins pipeline:"
        echo "   1. Replace playbook.yml with playbook_fixed.yml"
        echo "   2. Use ansible_jenkins.cfg in Jenkins environment"
        echo "   3. Run create_dynamic_inventory.sh before Ansible"
        echo "   4. Test with test_ansible_connection.sh"
        echo ""
        echo "🔧 Jenkins pipeline integration:"
        echo "   - Copy ansible_jenkins.cfg to ANSIBLE_CONFIG"
        echo "   - Run dynamic inventory creation"
        echo "   - Use inventory_dynamic.ini for playbook execution"
    else
        print_status "ERROR" "Some issues need to be resolved first"
        echo "Please fix the issues mentioned above before proceeding."
    fi
    
    return $exit_code
}

# Run the main function
main "$@"
