# Ansible Jenkins Pipeline Troubleshooting Guide

## 🚨 Common Ansible Issues in Jenkins Pipeline

### Issue 1: SSH Connection Failures

**Symptoms:**
- "Connection timed out" errors
- "Permission denied (publickey)" errors
- "Host key verification failed"

**Root Causes & Solutions:**

#### A. SSH Key Issues
```bash
# Problem: Key file not found or wrong permissions
# Solution:
chmod 400 redis-infra-key.pem
ls -la redis-infra-key.pem  # Should show -r--------
```

#### B. Bastion Host Configuration
```yaml
# Problem: Incorrect ProxyCommand configuration
# Solution in inventory:
ansible_ssh_common_args: >-
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o ProxyCommand="ssh -W %h:%p -i ./redis-infra-key.pem -o StrictHostKeyChecking=no ubuntu@BASTION_IP"
```

#### C. Security Group Rules
```bash
# Check security group allows SSH from bastion
aws ec2 describe-security-groups --group-names "private-sg" --region ap-south-1
```

### Issue 2: Inventory Problems

**Symptoms:**
- "No hosts matched" errors
- "Could not match supplied host pattern"
- Empty inventory warnings

**Solutions:**

#### A. Dynamic Inventory Issues
```bash
# Test AWS EC2 plugin
ansible-inventory -i aws_ec2.yaml --list

# Check AWS credentials
aws sts get-caller-identity

# Verify EC2 instances exist
aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:Name,Values=redis-*"
```

#### B. Static Inventory Creation
```ini
# Create manual inventory if dynamic fails
[redis_nodes]
redis-node-1 ansible_host=10.0.2.x ansible_user=ubuntu
redis-node-2 ansible_host=10.0.3.x ansible_user=ubuntu
redis-node-3 ansible_host=10.0.4.x ansible_user=ubuntu

[redis_nodes:vars]
ansible_ssh_private_key_file=./redis-infra-key.pem
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -i ./redis-infra-key.pem ubuntu@BASTION_IP"
```

### Issue 3: Role Structure Problems

**Symptoms:**
- "Role 'ansible' not found" errors
- "Could not find specified role" errors

**Solution:**
```bash
# Fix role structure
mkdir -p ansible/roles/redis/{tasks,handlers,templates,vars}
mv ansible/tasks/main.yml ansible/roles/redis/tasks/main.yml
mv ansible/handlers/main.yml ansible/roles/redis/handlers/main.yml
```

### Issue 4: Python/Boto3 Dependencies

**Symptoms:**
- "boto3 required for this module" errors
- "botocore required" errors

**Solutions:**
```bash
# Install on Jenkins agent
pip3 install boto3 botocore

# Or in playbook
- name: Install boto3
  pip:
    name: boto3
    state: present
```

## 🔧 Step-by-Step Ansible Fix

### Step 1: Replace Your Current Files

```bash
# Backup current files
mv playbook.yml playbook_original.yml
mv ansible.cfg ansible_original.cfg

# Use fixed versions
mv playbook_fixed.yml playbook.yml
mv ansible_jenkins.cfg ansible.cfg
```

### Step 2: Update Your Jenkinsfile

Replace your current Jenkinsfile with `Jenkinsfile_Ansible_Fixed` which includes:
- Better error handling for Ansible
- Dynamic inventory creation
- SSH connectivity testing
- Proper timeout configurations
- Comprehensive logging

### Step 3: Test Ansible Connectivity

```bash
# Run the test script
./test_ansible_connection.sh

# Manual testing
ansible all -i inventory_dynamic.ini -m ping
ansible all -i inventory_dynamic.ini -m setup -a "filter=ansible_default_ipv4"
```

## 🛠️ Jenkins Pipeline Integration

### Environment Variables
```groovy
environment {
    ANSIBLE_CONFIG = './ansible_jenkins.cfg'
    ANSIBLE_HOST_KEY_CHECKING = 'False'
    ANSIBLE_SSH_RETRIES = '3'
    ANSIBLE_TIMEOUT = '60'
    ANSIBLE_FORCE_COLOR = 'true'
}
```

### Ansible Stage Implementation
```groovy
stage('Ansible Configuration') {
    steps {
        sh '''
            # Set up Ansible environment
            export ANSIBLE_CONFIG="./ansible_jenkins.cfg"
            
            # Create dynamic inventory
            ./create_dynamic_inventory.sh
            
            # Test connectivity
            ansible all -i inventory_dynamic.ini -m ping --timeout=30
            
            # Run playbook
            ansible-playbook -i inventory_dynamic.ini playbook.yml \
                --extra-vars "bastion_host=$PUBLIC_IP" \
                --timeout=60 -v
        '''
    }
}
```

## 🔍 Debugging Commands

### Check Ansible Configuration
```bash
# Show current config
ansible-config dump

# Test inventory
ansible-inventory -i aws_ec2.yaml --list
ansible-inventory -i inventory_dynamic.ini --graph

# Test connectivity
ansible all -i inventory_dynamic.ini -m ping -vvv
```

### SSH Debugging
```bash
# Test direct SSH to bastion
ssh -i redis-infra-key.pem -o ConnectTimeout=10 ubuntu@BASTION_IP

# Test SSH through bastion
ssh -i redis-infra-key.pem -o ProxyCommand="ssh -W %h:%p -i redis-infra-key.pem ubuntu@BASTION_IP" ubuntu@PRIVATE_IP

# Debug SSH connection
ssh -i redis-infra-key.pem -vvv ubuntu@BASTION_IP
```

### AWS Resource Verification
```bash
# Check instances are running
aws ec2 describe-instances --region ap-south-1 \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`].Value|[0],State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}'

# Check security groups
aws ec2 describe-security-groups --region ap-south-1 \
    --filters "Name=group-name,Values=*redis*"
```

## 📋 Ansible Configuration Files

### Fixed Playbook Structure
```yaml
---
- name: Configure Redis Cluster
  hosts: all
  become: yes
  gather_facts: yes
  vars:
    ansible_ssh_user: ubuntu
    ansible_ssh_private_key_file: "./redis-infra-key.pem"
  
  pre_tasks:
    - name: Wait for system to become reachable
      wait_for_connection:
        timeout: 300
    
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
  
  tasks:
    - name: Install Redis
      apt:
        name: redis-server
        state: present
    
    # ... other tasks
```

### Jenkins-Compatible ansible.cfg
```ini
[defaults]
host_key_checking = False
remote_user = ubuntu
private_key_file = ./redis-infra-key.pem
timeout = 60
gathering = smart
retry_files_enabled = False
log_path = ./ansible.log

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=300s -o StrictHostKeyChecking=no -o ConnectTimeout=30
pipelining = True
retries = 3
```

## 🚀 Best Practices for Jenkins Ansible

### 1. Error Handling
```groovy
// Retry Ansible execution on failure
ansible-playbook playbook.yml || {
    echo "First attempt failed, retrying..."
    sleep 30
    ansible-playbook playbook.yml
}
```

### 2. Logging and Debugging
```groovy
// Enable verbose logging
ansible-playbook playbook.yml -vv

// Archive logs
archiveArtifacts artifacts: 'ansible.log', allowEmptyArchive: true
```

### 3. Timeout Management
```yaml
# In playbook
- name: Long running task
  command: some_command
  async: 300
  poll: 10
```

### 4. Connection Testing
```bash
# Always test connectivity first
ansible all -i inventory -m ping --timeout=30 || {
    echo "Connectivity test failed"
    exit 1
}
```

## 📞 Troubleshooting Checklist

### Before Running Ansible:
- [ ] SSH key file exists and has correct permissions (400)
- [ ] All EC2 instances are in "running" state
- [ ] Security groups allow SSH access (port 22)
- [ ] Bastion host is accessible from Jenkins
- [ ] AWS credentials are configured correctly

### During Ansible Execution:
- [ ] Inventory file is created successfully
- [ ] Connectivity test passes
- [ ] SSH through bastion works
- [ ] Target hosts are reachable
- [ ] Required packages can be installed

### After Ansible Execution:
- [ ] Redis service is running on all nodes
- [ ] Redis cluster is configured correctly
- [ ] Health checks pass
- [ ] Logs are archived for debugging

## 🔄 Recovery Procedures

### If Ansible Fails Completely:
1. **Manual Configuration:**
   ```bash
   # Connect to each Redis node manually
   ssh -i redis-infra-key.pem -J ubuntu@BASTION_IP ubuntu@REDIS_NODE_IP
   
   # Install Redis manually
   sudo apt update
   sudo apt install redis-server -y
   ```

2. **Partial Recovery:**
   ```bash
   # Run specific Ansible tasks
   ansible-playbook playbook.yml --tags "redis-install"
   ansible-playbook playbook.yml --start-at-task "Configure Redis"
   ```

3. **Debug Mode:**
   ```bash
   # Run with maximum verbosity
   ansible-playbook playbook.yml -vvvv
   ```

## 📈 Performance Optimization

### Parallel Execution
```yaml
# In playbook
strategy: free
serial: 3  # Run on 3 hosts simultaneously
```

### Connection Optimization
```ini
# In ansible.cfg
[ssh_connection]
pipelining = True
control_path = ~/.ansible/cp/%%h-%%p-%%r
```

### Fact Caching
```ini
# In ansible.cfg
[defaults]
gathering = smart
fact_caching = memory
fact_caching_timeout = 3600
```

This comprehensive troubleshooting guide should help you resolve most Ansible issues in your Jenkins pipeline. The key is systematic debugging and proper configuration management.
