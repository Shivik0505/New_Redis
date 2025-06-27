#!/bin/bash

# Fix Ansible Role Path Issues for Jenkins Pipeline
# Resolves role path and inventory conflicts

set -e

echo "🔧 Fixing Ansible Role Path Issues"
echo "=================================="

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

# Fix 1: Update ansible.cfg to include correct role path
fix_ansible_config() {
    echo -e "\n${BLUE}1. Fixing Ansible Configuration${NC}"
    echo "==============================="
    
    cat > ansible.cfg << 'EOF'
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
roles_path = ./ansible/roles:./roles:~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles
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
    
    print_status "SUCCESS" "Updated ansible.cfg with correct roles_path"
}

# Fix 2: Create a working playbook without role path issues
create_working_playbook() {
    echo -e "\n${BLUE}2. Creating Working Playbook${NC}"
    echo "=========================="
    
    cat > playbook-working.yml << 'EOF'
---
- name: Configure Redis Cluster
  hosts: redis_nodes
  become: yes
  gather_facts: yes
  vars:
    ansible_ssh_private_key_file: "./redis-infra-key.pem"
    ansible_ssh_user: ubuntu
    ansible_ssh_common_args: >-
      -o StrictHostKeyChecking=no
      -o UserKnownHostsFile=/dev/null
      -o ConnectTimeout=30
      -o ServerAliveInterval=60
      -o ServerAliveCountMax=3
      {% if bastion_host is defined %}
      -o ProxyCommand="ssh -W %h:%p -i {{ ansible_ssh_private_key_file }} -o StrictHostKeyChecking=no -o ConnectTimeout=30 ubuntu@{{ bastion_host }}"
      {% endif %}
  
  pre_tasks:
    - name: Wait for system to become reachable
      wait_for_connection:
        connect_timeout: 30
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
    
    print_status "SUCCESS" "Created working playbook without role dependencies"
}

# Fix 3: Create inventory without naming conflicts
create_clean_inventory() {
    echo -e "\n${BLUE}3. Creating Clean Inventory Script${NC}"
    echo "================================="
    
    cat > create-clean-inventory.sh << 'EOF'
#!/bin/bash

# Create Clean Inventory without naming conflicts
set -e

echo "🔧 Creating clean Ansible inventory..."

# Get running instances
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

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    echo "❌ No running bastion host found"
    exit 1
fi

if [ ${#PRIVATE_IPS[@]} -ne 3 ]; then
    echo "❌ Expected 3 Redis nodes, found ${#PRIVATE_IPS[@]}"
    exit 1
fi

echo "Discovered instances:"
echo "  Bastion (Public): $PUBLIC_IP"
echo "  Redis Node 1: ${PRIVATE_IPS[0]}"
echo "  Redis Node 2: ${PRIVATE_IPS[1]}"
echo "  Redis Node 3: ${PRIVATE_IPS[2]}"

# Create clean inventory without conflicts
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

echo "✅ Clean inventory created: inventory.ini"
EOF
    
    chmod +x create-clean-inventory.sh
    print_status "SUCCESS" "Created clean inventory script"
}

# Fix 4: Update the original playbook to work without roles
fix_original_playbook() {
    echo -e "\n${BLUE}4. Fixing Original Playbook${NC}"
    echo "=========================="
    
    # Backup original playbook
    if [ -f "playbook.yml" ]; then
        cp playbook.yml playbook-original-backup.yml
        print_status "INFO" "Backed up original playbook"
    fi
    
    # Replace with working version
    cp playbook-working.yml playbook.yml
    print_status "SUCCESS" "Updated playbook.yml with working version"
}

# Fix 5: Create comprehensive test script
create_test_script() {
    echo -e "\n${BLUE}5. Creating Comprehensive Test Script${NC}"
    echo "===================================="
    
    cat > test-complete-setup.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing Complete Ansible Setup"
echo "================================="

# Check if key file exists
if [ ! -f "redis-infra-key.pem" ]; then
    echo "❌ SSH key file not found: redis-infra-key.pem"
    exit 1
fi

chmod 400 redis-infra-key.pem
echo "✅ SSH key permissions set"

# Create inventory
echo "📋 Creating inventory..."
./create-clean-inventory.sh

# Test Ansible configuration
echo "🔧 Testing Ansible configuration..."
ansible-config dump | grep roles_path || echo "⚠️ roles_path not found in config"

# Test connectivity
echo "🔗 Testing connectivity..."
ansible all -i inventory.ini -m ping --timeout=30 || {
    echo "❌ Connectivity test failed"
    exit 1
}

echo "✅ Connectivity test passed"

# Test playbook syntax
echo "📝 Testing playbook syntax..."
ansible-playbook --syntax-check playbook.yml || {
    echo "❌ Playbook syntax check failed"
    exit 1
}

echo "✅ Playbook syntax is valid"

# Run playbook in check mode
echo "🚀 Running playbook in check mode..."
ansible-playbook -i inventory.ini playbook.yml --check --diff || {
    echo "❌ Playbook check mode failed"
    exit 1
}

echo "✅ Playbook check mode passed"
echo "🎉 All tests passed! Ready for deployment."
EOF
    
    chmod +x test-complete-setup.sh
    print_status "SUCCESS" "Created comprehensive test script"
}

# Main execution
main() {
    echo "Starting Ansible role path fix..."
    echo "Current directory: $(pwd)"
    echo ""
    
    fix_ansible_config
    create_working_playbook
    create_clean_inventory
    fix_original_playbook
    create_test_script
    
    echo -e "\n${BLUE}📋 Ansible Role Path Fix Summary${NC}"
    echo "================================="
    
    print_status "SUCCESS" "All Ansible fixes applied successfully!"
    echo ""
    echo "✅ Files created/updated:"
    echo "   - ansible.cfg (updated with correct roles_path)"
    echo "   - playbook.yml (fixed to work without role dependencies)"
    echo "   - playbook-working.yml (working version without roles)"
    echo "   - create-clean-inventory.sh (clean inventory creation)"
    echo "   - test-complete-setup.sh (comprehensive testing)"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Test the setup: ./test-complete-setup.sh"
    echo "   2. Push changes to GitHub"
    echo "   3. Jenkins SCM polling will detect changes"
    echo "   4. Pipeline should now run successfully"
    echo ""
    echo "🔧 Key fixes applied:"
    echo "   - Fixed roles_path in ansible.cfg"
    echo "   - Removed role dependencies from playbook"
    echo "   - Fixed inventory naming conflicts"
    echo "   - Added comprehensive error handling"
    
    return 0
}

# Run the main function
main "$@"
