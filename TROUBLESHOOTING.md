# Redis Infrastructure Troubleshooting Guide

## Quick Validation
Run `./validate-setup.sh` to check for common issues.

## Common Issues and Solutions

### 1. Region Mismatch
**Problem**: AWS CLI and Terraform configured for different regions
**Solution**: Run `./configure-region.sh` to synchronize regions

### 2. Key Pair Issues
**Problem**: `InvalidKeyPair.NotFound` error
**Solution**: 
```bash
# Delete existing key pair and recreate
aws ec2 delete-key-pair --key-name my-key-aws --region <your-region>
aws ec2 create-key-pair --key-name my-key-aws --region <your-region> --query 'KeyMaterial' --output text > my-key-aws.pem
chmod 400 my-key-aws.pem
```

### 3. AMI Not Found
**Problem**: AMI ID not available in your region
**Solution**: Find the correct Ubuntu 22.04 LTS AMI for your region
```bash
aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" --query 'Images[*].[ImageId,Name,CreationDate]' --output table --region <your-region>
```
Update the AMI ID in `terraform/instances/variable.tf`

### 4. VPC Limit Exceeded
**Problem**: `VpcLimitExceeded` error
**Solution**: 
```bash
# Clean up unused VPCs
./quick-cleanup.sh
# Or manually delete unused VPCs in AWS console
```

### 5. Security Group Conflicts
**Problem**: `InvalidGroup.Duplicate` error
**Solution**: 
```bash
./cleanup-conflicts.sh
```

### 6. Terraform State Issues
**Problem**: State file corruption or conflicts
**Solution**: 
```bash
cd terraform
terraform refresh
# If that doesn't work:
rm -rf .terraform terraform.tfstate*
terraform init
```

### 7. Ansible Connection Issues
**Problem**: Cannot connect to instances via Ansible
**Solutions**:
- Ensure key file permissions: `chmod 400 my-key-aws.pem`
- Check security groups allow SSH (port 22)
- Verify instances are running
- For private instances, ensure bastion host is accessible

### 8. Redis Cluster Setup Issues
**Problem**: Redis nodes cannot form cluster
**Solutions**:
- Check security groups allow Redis ports (6379, 16379-16384)
- Verify Redis configuration allows clustering
- Ensure nodes can communicate with each other

## Validation Commands

### Check AWS Configuration
```bash
aws sts get-caller-identity
aws ec2 describe-regions --region us-east-1
```

### Check Terraform
```bash
cd terraform
terraform validate
terraform plan
```

### Check Ansible
```bash
ansible --version
ansible-inventory -i aws_ec2.yaml --list
ansible all -i aws_ec2.yaml -m ping
```

### Check Infrastructure
```bash
# List running instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`].Value|[0],State:State.Name,IP:PublicIpAddress}' --output table

# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*redis*" --query 'SecurityGroups[].{Name:GroupName,ID:GroupId,VPC:VpcId}' --output table
```

## Clean Deployment Process

1. **Validate setup**: `./validate-setup.sh`
2. **Fix any issues** identified by validation
3. **Configure regions**: `./configure-region.sh` (if needed)
4. **Clean up conflicts**: `./cleanup-conflicts.sh`
5. **Deploy infrastructure**: `./deploy-infrastructure.sh`
6. **Configure Redis**: `ansible-playbook -i aws_ec2.yaml playbook.yml`

## Emergency Cleanup

If deployment fails and resources are stuck:

```bash
# Quick cleanup of common resources
./quick-cleanup.sh

# Comprehensive cleanup (interactive)
./cleanup-aws-resources.sh

# Nuclear option - destroy everything via Terraform
cd terraform
terraform destroy --auto-approve
```

## Getting Help

1. Check AWS CloudTrail for detailed error logs
2. Review Terraform state: `terraform show`
3. Check Ansible logs with `-vvv` flag for verbose output
4. Verify AWS service limits and quotas

## Useful AWS CLI Commands

```bash
# Check service limits
aws service-quotas get-service-quota --service-code ec2 --quota-code L-F678F1CE

# List all VPCs
aws ec2 describe-vpcs --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock,Default:IsDefault,State:State}' --output table

# List all key pairs
aws ec2 describe-key-pairs --query 'KeyPairs[].KeyName' --output table

# Check Elastic IP usage
aws ec2 describe-addresses --query 'Addresses[].{IP:PublicIp,Instance:InstanceId,Associated:AssociationId}' --output table
```
