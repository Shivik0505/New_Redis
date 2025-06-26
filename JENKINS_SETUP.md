# Jenkins Setup Guide for Redis Infrastructure Deployment

## Overview
This guide will help you set up Jenkins for automated deployment of the Redis infrastructure using SCM polling.

## Prerequisites
- Jenkins server running
- Git plugin installed
- AWS CLI plugin installed
- Ansible plugin installed (optional)

## Step 1: Configure AWS Credentials in Jenkins

### Method 1: Using Jenkins Credentials Manager
1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click on **(global)** domain
3. Click **Add Credentials**
4. Add the following credentials:

**AWS Access Key ID:**
- Kind: Secret text
- Secret: Your AWS Access Key ID
- ID: `AWS_ACCESS_KEY_ID`
- Description: AWS Access Key ID for Redis Infrastructure

**AWS Secret Access Key:**
- Kind: Secret text
- Secret: Your AWS Secret Access Key
- ID: `AWS_SECRET_ACCESS_KEY`
- Description: AWS Secret Access Key for Redis Infrastructure

### Method 2: Using Environment Variables (Alternative)
Add these to your Jenkins environment:
```bash
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
```

## Step 2: Create Jenkins Pipeline Job

1. **Create New Job:**
   - Go to Jenkins dashboard
   - Click **New Item**
   - Enter name: `Redis-Infrastructure-Pipeline`
   - Select **Pipeline**
   - Click **OK**

2. **Configure General Settings:**
   - Description: `Automated Redis Infrastructure Deployment with SCM Polling`
   - Check **GitHub project** (if using GitHub)
   - Project URL: `https://github.com/your-username/your-repo-name`

3. **Configure Build Triggers:**
   - Check **Poll SCM**
   - Schedule: `H/5 * * * *` (polls every 5 minutes)
   - Or use `H/2 * * * *` for every 2 minutes (more frequent)

4. **Configure Pipeline:**
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/your-username/your-repo-name.git`
   - Credentials: Add your Git credentials if private repo
   - Branch: `*/main` or `*/master`
   - Script Path: `Jenkinsfile`

5. **Configure Parameters (Optional):**
   The pipeline includes these default parameters:
   - `autoApprove`: true (for automatic deployment)
   - `action`: apply
   - `keyPairName`: redis-infra-key
   - `recreateKeyPair`: false
   - `skipAnsible`: false

## Step 3: Test the Setup

1. **Manual Trigger:**
   - Go to your pipeline job
   - Click **Build with Parameters**
   - Use default values for first test
   - Click **Build**

2. **SCM Polling Test:**
   - Make a small change to your repository (e.g., update README)
   - Commit and push the change
   - Wait for the polling interval (up to 5 minutes)
   - Check if Jenkins automatically triggers the build

## Step 4: Monitor and Troubleshoot

### Common Issues and Solutions

#### 1. AWS Credentials Not Found
**Error:** `Unable to locate credentials`
**Solution:** 
- Verify credentials are added with correct IDs
- Check credential scope (should be global)
- Ensure Jenkins has permission to access credentials

#### 2. SCM Polling Not Working
**Error:** No automatic builds triggered
**Solution:**
- Check Jenkins logs: **Manage Jenkins** → **System Log**
- Verify repository URL is accessible
- Check polling schedule syntax
- Ensure webhook permissions if using webhooks

#### 3. Terraform/Ansible Not Found
**Error:** `terraform: command not found`
**Solution:**
- Install tools on Jenkins agent/master
- Or use Docker-based Jenkins agents with pre-installed tools

### Monitoring Pipeline Execution

1. **Build History:**
   - Check build history for success/failure patterns
   - Review console output for detailed logs

2. **Pipeline Stage View:**
   - Use Blue Ocean plugin for better visualization
   - Monitor stage-by-stage execution

3. **Artifacts:**
   - Download connection guide from build artifacts
   - Download private key file for SSH access
   - Review Terraform outputs

## Step 5: Advanced Configuration

### Enable Notifications
Add to your Jenkinsfile post section:
```groovy
post {
    success {
        emailext (
            subject: "✅ Redis Infrastructure Deployed Successfully",
            body: "The Redis infrastructure has been deployed successfully. Check the build artifacts for connection details.",
            to: "your-email@example.com"
        )
    }
    failure {
        emailext (
            subject: "❌ Redis Infrastructure Deployment Failed",
            body: "The Redis infrastructure deployment failed. Check the build logs for details.",
            to: "your-email@example.com"
        )
    }
}
```

### Webhook Integration (Alternative to Polling)
Instead of SCM polling, you can use webhooks for instant triggers:

1. **GitHub Webhook:**
   - Go to your GitHub repository
   - Settings → Webhooks → Add webhook
   - Payload URL: `http://your-jenkins-url/github-webhook/`
   - Content type: `application/json`
   - Events: Just the push event

2. **Update Jenkins Job:**
   - Remove SCM polling
   - Check **GitHub hook trigger for GITScm polling**

### Multi-Environment Support
Create separate pipeline jobs for different environments:
- `Redis-Infrastructure-Dev`
- `Redis-Infrastructure-Staging`
- `Redis-Infrastructure-Prod`

Each with different parameters and branch configurations.

## Step 6: Security Best Practices

1. **Credential Management:**
   - Use Jenkins credential store
   - Rotate AWS keys regularly
   - Use IAM roles when possible

2. **Access Control:**
   - Limit who can trigger deployments
   - Use role-based access control
   - Enable audit logging

3. **Resource Management:**
   - Set up resource tagging
   - Implement cost monitoring
   - Use resource limits

## Troubleshooting Commands

### Check Jenkins Logs
```bash
# On Jenkins server
tail -f /var/log/jenkins/jenkins.log

# Or through Jenkins UI
# Manage Jenkins → System Log → All Jenkins Logs
```

### Test AWS Connectivity
```bash
# From Jenkins agent/master
aws sts get-caller-identity
aws ec2 describe-regions
```

### Validate Terraform
```bash
# In your repository
cd terraform/
terraform init
terraform validate
terraform plan
```

## Support and Maintenance

### Regular Tasks
- Monitor build success rates
- Review and rotate credentials
- Update Jenkins plugins
- Clean up old build artifacts
- Monitor AWS costs

### Backup Strategy
- Backup Jenkins configuration
- Store Terraform state in S3 backend
- Document infrastructure changes
- Keep deployment artifacts

## Next Steps

After successful setup:
1. Test the complete deployment cycle
2. Set up monitoring for deployed infrastructure
3. Configure backup strategies
4. Document operational procedures
5. Train team members on the deployment process

---

**Happy Deploying with Jenkins! 🚀**
