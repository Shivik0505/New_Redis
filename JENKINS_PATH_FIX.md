# Jenkins PATH Configuration Fix

## Issue Fixed
The Jenkins pipeline was failing with `aws: command not found` because Jenkins couldn't find the AWS CLI and other tools installed via Homebrew.

## Solutions Applied

### 1. ✅ Tools Installed
- **AWS CLI**: v2.27.43 (upgraded)
- **Terraform**: v1.12.1 (already installed)
- **Ansible**: v11.7.0_1 (upgraded)
- **Ansible Collections**: amazon.aws, community.aws

### 2. ✅ PATH Configuration Updated
Updated Jenkinsfile with proper PATH:
```groovy
environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
    KEY_PAIR_NAME = "${params.keyPairName}"
    TF_IN_AUTOMATION = 'true'
    TF_INPUT = 'false'
    PATH = "/opt/homebrew/bin:/usr/local/bin:${env.PATH}"
}
```

### 3. ✅ Key Pair Updated
- Old key: `my-key-aws` (deleted)
- New key: `redis-infra-key` (created and configured)

## Additional Jenkins Configuration (If Still Having Issues)

### Option 1: Configure Jenkins Global Tool Configuration
1. Go to **Manage Jenkins** → **Global Tool Configuration**
2. Add custom tools:
   - **Name**: AWS CLI
   - **Installation directory**: `/opt/homebrew/bin`

### Option 2: Update Jenkins Node Configuration
1. Go to **Manage Jenkins** → **Manage Nodes and Clouds**
2. Click on your node (or master)
3. Click **Configure**
4. Add Environment Variables:
   - **Name**: `PATH`
   - **Value**: `/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin`

### Option 3: Jenkins Service Configuration (macOS)
If Jenkins is running as a service, update the service configuration:

```bash
# Edit Jenkins service (if using launchd)
sudo nano /Library/LaunchDaemons/org.jenkins-ci.plist

# Add environment variables:
<key>EnvironmentVariables</key>
<dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
</dict>

# Restart Jenkins service
sudo launchctl unload /Library/LaunchDaemons/org.jenkins-ci.plist
sudo launchctl load /Library/LaunchDaemons/org.jenkins-ci.plist
```

## Verification Steps

### 1. Test Tools Locally
Run the test script:
```bash
./test-tools.sh
```

### 2. Test in Jenkins
Create a simple Jenkins job with this script:
```bash
#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
echo "PATH: $PATH"
aws --version
terraform --version
ansible --version
```

### 3. Monitor Pipeline
- Check Jenkins console output
- Verify SCM polling is working (should trigger every 5 minutes)
- Monitor build history for automatic triggers

## Current Status
✅ All tools installed and working
✅ PATH configuration updated in Jenkinsfile
✅ New key pair created and configured
✅ Changes committed and pushed to trigger SCM polling

## Next Steps
1. Monitor Jenkins for automatic build trigger (within 5 minutes)
2. Check build console output for successful tool detection
3. Verify infrastructure deployment completes successfully
4. Download connection guide and key file from Jenkins artifacts

## Troubleshooting
If you still encounter issues:

1. **Check Jenkins logs**:
   ```bash
   tail -f /var/log/jenkins/jenkins.log
   ```

2. **Verify Jenkins can execute commands**:
   Create a test job with: `which aws && aws --version`

3. **Check Jenkins user permissions**:
   Ensure Jenkins user can access `/opt/homebrew/bin`

4. **Restart Jenkins**:
   ```bash
   sudo brew services restart jenkins
   ```
