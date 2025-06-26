# Jenkins One-Click Deployment Guide

## Overview
This guide explains how to set up and use Jenkins for one-click deployment of your Redis infrastructure on AWS.

## Prerequisites

### Jenkins Setup
1. **Jenkins Server** with the following plugins installed:
   - Git plugin
   - Pipeline plugin
   - AWS CLI plugin (optional)
   - Ansible plugin (optional)

2. **Jenkins Credentials** configured:
   - `AWS_ACCESS_KEY_ID` (String credential)
   - `AWS_SECRET_ACCESS_KEY` (String credential)

### Local Setup
1. **Generate/Update Key Pair**:
   ```bash
   ./generate-new-keypair.sh
   ```

2. **Validate Configuration**:
   ```bash
   ./validate-setup.sh
   ```

3. **Complete Jenkins Setup**:
   ```bash
   ./setup-for-jenkins.sh
   ```

## Jenkins Pipeline Parameters

The enhanced Jenkinsfile supports the following parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `autoApprove` | Boolean | `false` | Enable one-click deployment |
| `action` | Choice | `apply` | `apply` to deploy, `destroy` to cleanup |
| `keyPairName` | String | `my-key-aws` | AWS Key Pair name to use |
| `recreateKeyPair` | Boolean | `false` | Force recreate key pair if exists |

## One-Click Deployment Steps

### 1. Setup Jenkins Job
1. Create a new **Pipeline** job in Jenkins
2. Configure **Pipeline from SCM**:
   - SCM: Git
   - Repository URL: `https://github.com/JayLikhare316/redisdemo.git`
   - Branch: `master` (or your branch)
   - Script Path: `Jenkinsfile`

### 2. Configure Build Parameters
Set the following parameters for one-click deployment:
- ✅ `autoApprove`: `true`
- ✅ `action`: `apply`
- ✅ `keyPairName`: Your desired key name (e.g., `redis-demo-key`)
- ✅ `recreateKeyPair`: `false` (unless you want to force recreate)

### 3. Run the Pipeline
Click **"Build with Parameters"** and the pipeline will:
1. ✅ Clone the repository
2. ✅ Setup/create the key pair automatically
3. ✅ Initialize and validate Terraform
4. ✅ Plan the infrastructure deployment
5. ✅ Deploy the infrastructure
6. ✅ Wait for instances to be ready
7. ✅ Configure Redis cluster with Ansible
8. ✅ Verify the deployment

## Pipeline Stages Explained

### Stage 1: Clone Repository
- Pulls the latest code from your Git repository
- Ensures Jenkins has the latest configuration

### Stage 2: Setup Key Pair
- Checks if the specified key pair exists in AWS
- Creates a new key pair if it doesn't exist
- Optionally recreates the key pair if `recreateKeyPair` is true
- Updates Terraform configuration with the correct key name

### Stage 3: Plan
- Initializes Terraform
- Validates the configuration
- Creates an execution plan
- Archives the plan for review

### Stage 4: Apply/Destroy
- Applies the Terraform plan (for `apply` action)
- Destroys the infrastructure (for `destroy` action)
- Shows deployment summary

### Stage 5: Wait for Infrastructure
- Waits 90 seconds for instances to be fully ready
- Ensures all services are started

### Stage 6: Run Ansible Playbook
- Configures Redis on all instances
- Sets up Redis clustering
- Handles SSH key configuration automatically

### Stage 7: Deployment Verification
- Lists all deployed instances
- Shows connection information
- Provides next steps

## Key Features

### ✅ Automatic Key Management
- Creates key pairs automatically
- Handles key file permissions
- Archives key files for download
- Cleans up keys on destroy

### ✅ Error Handling
- Validates configuration at each step
- Provides clear error messages
- Handles missing dependencies gracefully

### ✅ Flexibility
- Supports custom key pair names
- Allows key pair recreation
- Works with existing key pairs

### ✅ Security
- Uses Jenkins credentials for AWS access
- Proper file permissions for SSH keys
- Secure key pair management

## Troubleshooting

### Common Issues

#### 1. AWS Credentials Not Found
**Error**: `Unable to locate credentials`
**Solution**: Ensure AWS credentials are configured in Jenkins:
- Go to Jenkins → Manage Jenkins → Manage Credentials
- Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

#### 2. Key Pair Already Exists
**Error**: `InvalidKeyPair.Duplicate`
**Solution**: Set `recreateKeyPair` parameter to `true`

#### 3. Region Mismatch
**Error**: AMI not found in region
**Solution**: 
- Update the region in `terraform/provider.tf`
- Update the AMI ID for your region
- Or run `./configure-region.sh` locally first

#### 4. Ansible Connection Failed
**Error**: SSH connection timeout
**Solution**: 
- Increase wait time in pipeline
- Check security groups allow SSH (port 22)
- Verify instances are in running state

### Debug Commands

```bash
# Check Jenkins workspace
ls -la /var/jenkins_home/workspace/your-job-name/

# Verify AWS credentials in Jenkins
aws sts get-caller-identity

# Check Terraform state
terraform show

# Test Ansible connectivity
ansible all -i aws_ec2.yaml -m ping --private-key=your-key.pem
```

## Manual Deployment Alternative

If Jenkins deployment fails, you can deploy manually:

```bash
# 1. Generate key pair
./generate-new-keypair.sh

# 2. Deploy infrastructure
./deploy-infrastructure.sh

# 3. Configure Redis
ansible-playbook -i aws_ec2.yaml playbook.yml --private-key=your-key.pem
```

## Cleanup

### Via Jenkins
1. Set parameters:
   - `autoApprove`: `true`
   - `action`: `destroy`
2. Run the pipeline

### Manual Cleanup
```bash
cd terraform
terraform destroy --auto-approve

# Clean up key pair
aws ec2 delete-key-pair --key-name your-key-name --region your-region
```

## Best Practices

1. **Version Control**: Always commit changes before Jenkins deployment
2. **Key Security**: Never commit `.pem` files to Git
3. **Resource Monitoring**: Monitor AWS costs and resource usage
4. **Regular Cleanup**: Destroy test environments when not needed
5. **Backup**: Keep backups of important configurations

## Next Steps After Deployment

1. **Connect to Bastion Host**:
   ```bash
   ssh -i your-key.pem ubuntu@<public-ip>
   ```

2. **Access Redis Nodes**:
   ```bash
   ssh -i your-key.pem -J ubuntu@<bastion-ip> ubuntu@<redis-node-ip>
   ```

3. **Test Redis Cluster**:
   ```bash
   redis-cli -c -h <redis-node-ip> -p 6379
   ```

4. **Monitor Resources**:
   - Check AWS Console for running instances
   - Monitor costs in AWS Billing dashboard

## Support

For issues:
1. Check the troubleshooting section above
2. Review Jenkins build logs
3. Check AWS CloudTrail for API errors
4. Validate configuration with `./validate-setup.sh`

---

🚀 **Your Redis infrastructure is now ready for one-click deployment via Jenkins!**
