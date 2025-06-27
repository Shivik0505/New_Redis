# Jenkins Pipeline Troubleshooting Guide

## Current Issue: create-inventory.sh not found

### Problem
The Jenkins pipeline is failing because it's looking for `./create-inventory.sh` which doesn't exist.

### Solution
1. The script `create-inventory.sh` has been created
2. It dynamically discovers AWS instances and creates inventory
3. Make sure it's executable: `chmod +x create-inventory.sh`

## Testing the Fix

### 1. Test Inventory Creation Locally
```bash
# Test the inventory script
./test-inventory.sh
```

### 2. Test Ansible Connectivity
```bash
# Create inventory
./create-inventory.sh

# Test connectivity
ansible all -i inventory.ini -m ping
```

### 3. Test Minimal Playbook
```bash
# Run minimal playbook
ansible-playbook -i inventory.ini playbook-minimal.yml
```

## Pipeline Fixes Applied

1. ✅ Created `create-inventory.sh` script
2. ✅ Fixed `playbook.yml` to use correct role structure
3. ✅ Verified Ansible role structure is correct
4. ✅ Created test scripts for validation

## Next Steps

1. Push these fixes to GitHub
2. Jenkins SCM polling will detect changes
3. Pipeline should now pass the inventory creation step
4. Monitor Ansible execution for any remaining issues

## If Pipeline Still Fails

### Check These Items:
- [ ] AWS credentials are configured in Jenkins
- [ ] EC2 instances are running
- [ ] Security groups allow SSH access
- [ ] SSH key permissions are correct (400)
- [ ] Bastion host is accessible

### Debug Commands:
```bash
# Check running instances
aws ec2 describe-instances --region ap-south-1 --filters "Name=instance-state-name,Values=running"

# Test SSH to bastion
ssh -i redis-infra-key.pem ubuntu@BASTION_IP

# Test Ansible ping
ansible all -i inventory.ini -m ping -vvv
```
