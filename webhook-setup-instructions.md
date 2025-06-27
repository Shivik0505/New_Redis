# GitHub Webhook Setup for Jenkins SCM Polling

## Quick Setup Guide

### Step 1: Configure GitHub Webhook

1. **Go to your GitHub repository:**
   - https://github.com/Shivik0505/New_Redis
   - Click "Settings" tab
   - Click "Webhooks" in left sidebar
   - Click "Add webhook"

2. **Configure webhook settings:**
   - **Payload URL**: `http://YOUR_JENKINS_URL/github-webhook/`
   - **Content type**: `application/json`
   - **Secret**: (leave empty for now, add later for security)
   - **Which events**: Select "Just the push event"
   - **Active**: ✅ Checked

3. **Save the webhook**

### Step 2: Configure Jenkins Job

1. **In your Jenkins job configuration:**
   - Go to "Build Triggers" section
   - Check "GitHub hook trigger for GITScm polling"
   - Save the configuration

### Step 3: Test the Setup

1. **Make a test commit:**
   ```bash
   echo "# Webhook test $(date)" >> README.md
   git add README.md
   git commit -m "Test webhook trigger"
   git push origin master
   ```

2. **Verify webhook delivery:**
   - Go back to GitHub webhook settings
   - Click on your webhook
   - Check "Recent Deliveries" tab
   - Should show successful delivery (green checkmark)

3. **Check Jenkins:**
   - Your job should trigger immediately after push
   - No need to wait for SCM polling

## Alternative: Jenkins GitHub Plugin Setup

### Step 1: Install GitHub Plugin

1. **In Jenkins:**
   - Manage Jenkins → Manage Plugins
   - Available tab → Search "GitHub Plugin"
   - Install and restart Jenkins

### Step 2: Configure GitHub Server

1. **In Jenkins:**
   - Manage Jenkins → Configure System
   - Find "GitHub" section
   - Add GitHub Server:
     - Name: `GitHub`
     - API URL: `https://api.github.com`
     - Credentials: Add GitHub personal access token

### Step 3: Create Personal Access Token

1. **In GitHub:**
   - Settings → Developer settings → Personal access tokens
   - Generate new token with these scopes:
     - `repo` (Full control of private repositories)
     - `admin:repo_hook` (Read and write repository hooks)

2. **Add token to Jenkins:**
   - Manage Jenkins → Credentials → System → Global credentials
   - Add Credentials → Secret text
   - Secret: Your GitHub token
   - ID: `github-token`

## Troubleshooting SCM Polling

### Issue 1: SCM Polling Not Working

**Check Jenkins System Log:**
1. Manage Jenkins → System Log
2. Add logger: `hudson.triggers.SCMTrigger`
3. Set level to `ALL`
4. Look for polling messages

**Common Solutions:**
- Verify cron syntax: `H/5 * * * *` (every 5 minutes)
- Check repository access from Jenkins server
- Ensure branch name matches in configuration

### Issue 2: Webhook Not Triggering

**Check Webhook Deliveries:**
1. GitHub → Repository → Settings → Webhooks
2. Click on your webhook
3. Check "Recent Deliveries"
4. Look for error messages

**Common Solutions:**
- Verify Jenkins URL is accessible from internet
- Check firewall settings
- Ensure webhook URL ends with `/github-webhook/`

### Issue 3: Authentication Issues

**For HTTPS repositories:**
- Use personal access token instead of password
- Configure credentials in Jenkins

**For SSH repositories:**
- Add SSH key to Jenkins
- Configure SSH agent

## Testing Your Setup

### Test SCM Polling

```bash
# Make a change
echo "# SCM test $(date)" >> README.md
git add README.md
git commit -m "Test SCM polling"
git push origin master

# Wait 5 minutes (or check Jenkins immediately if webhook is configured)
```

### Verify in Jenkins

1. **Check Git Polling Log:**
   - Go to your Jenkins job
   - Click "Git Polling Log" in sidebar
   - Should show recent polling activity

2. **Check Build History:**
   - Recent builds should show SCM or webhook triggers
   - Build description should indicate trigger source

## Recommended Configuration

### Jenkinsfile Triggers Section

```groovy
pipeline {
    agent any
    
    triggers {
        // SCM polling as backup
        pollSCM('H/5 * * * *')
    }
    
    // Optional: Add webhook trigger
    properties([
        pipelineTriggers([
            pollSCM('H/5 * * * *'),
            githubPush()
        ])
    ])
    
    // ... rest of pipeline
}
```

### Best Practices

1. **Use webhook for instant triggering**
2. **Keep SCM polling as backup**
3. **Set reasonable polling frequency (5-10 minutes)**
4. **Monitor Jenkins system logs**
5. **Test both webhook and polling**

## Security Considerations

### Webhook Security

1. **Add webhook secret:**
   - Generate random secret
   - Add to GitHub webhook configuration
   - Configure in Jenkins GitHub plugin

2. **Restrict webhook access:**
   - Use HTTPS for Jenkins
   - Configure firewall rules
   - Monitor webhook deliveries

### Jenkins Security

1. **Secure credentials:**
   - Use Jenkins credential store
   - Don't hardcode tokens in pipeline
   - Rotate tokens regularly

2. **Access control:**
   - Configure proper user permissions
   - Use role-based access control
   - Monitor build logs

## Monitoring and Maintenance

### Regular Checks

1. **Weekly:**
   - Check webhook delivery success rate
   - Review SCM polling logs
   - Verify build trigger patterns

2. **Monthly:**
   - Rotate GitHub tokens
   - Review Jenkins system logs
   - Update webhook configurations if needed

### Troubleshooting Commands

```bash
# Check git connectivity from Jenkins
git ls-remote https://github.com/Shivik0505/New_Redis.git

# Test webhook manually
curl -X POST http://YOUR_JENKINS_URL/github-webhook/ \
  -H "Content-Type: application/json" \
  -d '{"ref":"refs/heads/master"}'

# Check Jenkins process
ps aux | grep jenkins
netstat -tlnp | grep :8080
```

This setup ensures reliable triggering of your Jenkins pipeline whenever you push changes to your Redis infrastructure repository!
