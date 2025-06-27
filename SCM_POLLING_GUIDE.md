# SCM Polling Troubleshooting Guide

## 🚨 Common SCM Polling Issues and Solutions

### Issue 1: SCM Polling Not Working At All

**Symptoms:**
- Jenkins job never triggers automatically
- No SCM polling messages in Jenkins logs
- Manual builds work fine

**Root Causes & Solutions:**

#### A. Incorrect Cron Syntax
```groovy
// ❌ Wrong
triggers {
    pollSCM('5 * * * *')  // This runs at 5 minutes past every hour
}

// ✅ Correct
triggers {
    pollSCM('H/5 * * * *')  // This runs every 5 minutes
}
```

#### B. Jenkins SCM Polling Disabled
**Fix:**
1. Go to Jenkins → Manage Jenkins → Configure System
2. Check "Enable SCM polling" is enabled
3. Restart Jenkins if needed

#### C. Git Repository Access Issues
**Fix:**
```bash
# Test git access from Jenkins server
git ls-remote https://github.com/Shivik0505/New_Redis.git
```

### Issue 2: SCM Polling Runs But Doesn't Trigger Builds

**Symptoms:**
- SCM polling logs show "No changes detected"
- Polling happens but builds don't start
- Changes exist in repository

**Solutions:**

#### A. Branch Mismatch
```groovy
// In Jenkins job configuration
branches: [[name: '*/master']]  // Make sure this matches your actual branch
```

#### B. Polling User Permissions
**Fix:**
1. Ensure Jenkins has read access to repository
2. For private repos, configure credentials properly

#### C. Workspace Issues
**Fix:**
```bash
# Clean Jenkins workspace
rm -rf /var/jenkins_home/workspace/your-job-name/*
```

### Issue 3: SCM Polling Too Frequent or Infrequent

**Current Configuration:**
```groovy
pollSCM('H/5 * * * *')  // Every 5 minutes
```

**Alternative Schedules:**
```groovy
pollSCM('H/2 * * * *')   // Every 2 minutes
pollSCM('H/10 * * * *')  // Every 10 minutes
pollSCM('H * * * *')     // Every hour
pollSCM('H H/4 * * *')   // Every 4 hours
```

## 🔧 Complete SCM Polling Fix

### Step 1: Update Your Jenkinsfile

Replace your current triggers section:

```groovy
pipeline {
    agent any

    triggers {
        // Enhanced SCM polling with better error handling
        pollSCM('H/5 * * * *')
    }

    // Add this for webhook support (recommended)
    properties([
        pipelineTriggers([
            pollSCM('H/5 * * * *'),
            githubPush()  // Enable GitHub webhook trigger
        ])
    ])
    
    // Rest of your pipeline...
}
```

### Step 2: Configure GitHub Webhook (Recommended)

#### Option A: Automatic Setup via Jenkins GitHub Plugin

1. **Install GitHub Plugin:**
   - Go to Manage Jenkins → Manage Plugins
   - Install "GitHub Plugin"

2. **Configure GitHub Server:**
   - Manage Jenkins → Configure System
   - Add GitHub Server with personal access token

3. **Enable Webhook in Job:**
   - Job Configuration → Build Triggers
   - Check "GitHub hook trigger for GITScm polling"

#### Option B: Manual Webhook Setup

1. **Go to GitHub Repository:**
   - https://github.com/Shivik0505/New_Redis
   - Settings → Webhooks → Add webhook

2. **Configure Webhook:**
   - Payload URL: `http://YOUR_JENKINS_URL/github-webhook/`
   - Content type: `application/json`
   - Events: "Just the push event"
   - Active: ✅

### Step 3: Jenkins Job Configuration

#### Pipeline from SCM Configuration:
```xml
<definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition">
    <scm class="hudson.plugins.git.GitSCM">
        <configVersion>2</configVersion>
        <userRemoteConfigs>
            <hudson.plugins.git.UserRemoteConfig>
                <url>https://github.com/Shivik0505/New_Redis.git</url>
            </hudson.plugins.git.UserRemoteConfig>
        </userRemoteConfigs>
        <branches>
            <hudson.plugins.git.BranchSpec>
                <name>*/master</name>
            </hudson.plugins.git.BranchSpec>
        </branches>
        <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
        <extensions>
            <hudson.plugins.git.extensions.impl.CleanBeforeCheckout/>
        </extensions>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
</definition>
```

## 🔍 Debugging SCM Polling

### Check Jenkins System Logs

1. **Go to:** Manage Jenkins → System Log
2. **Look for:** SCM polling messages
3. **Common log entries:**
   ```
   Started on [timestamp]
   Using strategy: Default
   [poll] Last Built Revision: Revision [commit-hash]
   [poll] Latest remote head revision on refs/remotes/origin/master is: [commit-hash]
   Done. Took [time]
   Changes found
   ```

### Manual SCM Polling Test

```bash
# From Jenkins server or agent
cd /var/jenkins_home/workspace/your-job-name
git fetch origin
git log --oneline -5
```

### Check Git Configuration

```bash
# Verify remote URL
git remote -v

# Test connectivity
git ls-remote origin

# Check current branch
git branch -a
```

## 🚀 Enhanced SCM Polling Pipeline

Here's an improved Jenkinsfile with better SCM handling:

```groovy
pipeline {
    agent any

    triggers {
        pollSCM('H/5 * * * *')
    }

    options {
        // Keep only last 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        
        // Timeout after 1 hour
        timeout(time: 1, unit: 'HOURS')
        
        // Skip checkout, we'll do it explicitly
        skipDefaultCheckout(true)
    }

    stages {
        stage('SCM Checkout') {
            steps {
                script {
                    echo "=== Enhanced SCM Checkout ==="
                    
                    // Clean workspace before checkout
                    cleanWs()
                    
                    // Explicit checkout with detailed logging
                    def scmVars = checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/master']],
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [
                            [$class: 'CleanBeforeCheckout'],
                            [$class: 'CloneOption', depth: 1, noTags: false, shallow: true]
                        ],
                        userRemoteConfigs: [[
                            url: 'https://github.com/Shivik0505/New_Redis.git'
                        ]]
                    ])
                    
                    // Display SCM information
                    echo "✅ SCM Checkout completed"
                    echo "📋 SCM Variables:"
                    scmVars.each { key, value ->
                        echo "   ${key}: ${value}"
                    }
                    
                    // Additional git information
                    def gitCommit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
                    def gitMessage = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
                    def gitAuthor = sh(returnStdout: true, script: 'git log -1 --pretty=%an').trim()
                    
                    echo "📝 Latest Commit:"
                    echo "   Hash: ${gitCommit}"
                    echo "   Author: ${gitAuthor}"
                    echo "   Message: ${gitMessage}"
                    
                    // Store git info for later use
                    env.GIT_COMMIT_HASH = gitCommit
                    env.GIT_COMMIT_MESSAGE = gitMessage
                    env.GIT_COMMIT_AUTHOR = gitAuthor
                }
            }
        }

        stage('Build Trigger Analysis') {
            steps {
                script {
                    echo "=== Build Trigger Analysis ==="
                    
                    def buildCauses = currentBuild.getBuildCauses()
                    echo "🔄 Build Triggers:"
                    
                    buildCauses.each { cause ->
                        def causeType = cause.getClass().getSimpleName()
                        echo "   Type: ${causeType}"
                        
                        if (cause.hasProperty('shortDescription')) {
                            echo "   Description: ${cause.shortDescription}"
                        }
                        
                        // Specific handling for SCM trigger
                        if (causeType.contains('SCM')) {
                            echo "   ✅ Triggered by SCM polling"
                            env.TRIGGERED_BY_SCM = 'true'
                        }
                        
                        // Specific handling for GitHub webhook
                        if (causeType.contains('GitHub')) {
                            echo "   ✅ Triggered by GitHub webhook"
                            env.TRIGGERED_BY_WEBHOOK = 'true'
                        }
                    }
                    
                    // Log build context
                    echo "📊 Build Context:"
                    echo "   Build Number: ${BUILD_NUMBER}"
                    echo "   Build URL: ${BUILD_URL}"
                    echo "   Job Name: ${JOB_NAME}"
                    echo "   Workspace: ${WORKSPACE}"
                }
            }
        }

        // Continue with your existing pipeline stages...
        stage('Environment Setup') {
            steps {
                echo "=== Environment Setup ==="
                sh '''
                    echo "Pipeline Parameters:"
                    echo "- Git Commit: ${GIT_COMMIT_HASH}"
                    echo "- Git Author: ${GIT_COMMIT_AUTHOR}"
                    echo "- Triggered by SCM: ${TRIGGERED_BY_SCM:-false}"
                    echo "- Triggered by Webhook: ${TRIGGERED_BY_WEBHOOK:-false}"
                '''
            }
        }

        // Add your existing stages here...
    }

    post {
        always {
            script {
                // Create detailed build report
                def buildReport = """
=== SCM Polling Build Report ===
Build Number: ${BUILD_NUMBER}
Build URL: ${BUILD_URL}
Triggered by SCM: ${env.TRIGGERED_BY_SCM ?: 'false'}
Triggered by Webhook: ${env.TRIGGERED_BY_WEBHOOK ?: 'false'}

Git Information:
- Commit: ${env.GIT_COMMIT_HASH ?: 'N/A'}
- Author: ${env.GIT_COMMIT_AUTHOR ?: 'N/A'}
- Message: ${env.GIT_COMMIT_MESSAGE ?: 'N/A'}

Build Time: ${new Date()}
Duration: ${currentBuild.durationString}
Result: ${currentBuild.result ?: 'SUCCESS'}
"""
                
                writeFile file: 'scm-build-report.txt', text: buildReport
                archiveArtifacts artifacts: 'scm-build-report.txt', allowEmptyArchive: true
                
                echo buildReport
            }
        }
        
        success {
            echo '✅ SCM-triggered pipeline completed successfully!'
        }
        
        failure {
            echo '❌ SCM-triggered pipeline failed!'
            echo 'Check the SCM configuration and repository access.'
        }
    }
}
```

## 🧪 Testing SCM Polling

### Test 1: Manual Trigger Test
```bash
# Make a small change
echo "# SCM Test $(date)" >> README.md
git add README.md
git commit -m "Test SCM polling - $(date)"
git push origin master
```

### Test 2: Verify Polling in Jenkins
1. Go to your Jenkins job
2. Click "Git Polling Log" in the left sidebar
3. Look for recent polling activity

### Test 3: Check Jenkins System Log
1. Manage Jenkins → System Log
2. Add logger for `hudson.triggers.SCMTrigger`
3. Set level to `FINE` or `ALL`

## 📋 SCM Polling Checklist

- [ ] Correct cron syntax in `pollSCM()`
- [ ] Repository URL is accessible from Jenkins
- [ ] Branch name matches in configuration
- [ ] Jenkins has proper Git credentials (if needed)
- [ ] SCM polling is enabled in Jenkins system settings
- [ ] Workspace has proper permissions
- [ ] Git repository has recent commits to detect
- [ ] Jenkins system has sufficient resources
- [ ] Network connectivity to GitHub is working
- [ ] GitHub webhook is configured (optional but recommended)

## 🎯 Recommended Configuration

For optimal SCM polling performance:

```groovy
pipeline {
    agent any
    
    triggers {
        pollSCM('H/5 * * * *')  // Every 5 minutes
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        skipDefaultCheckout(true)
    }
    
    // Use explicit checkout for better control
    // Enable GitHub webhook for instant triggering
    // Monitor Jenkins logs for polling activity
}
```

This configuration provides:
- ✅ Reliable SCM polling every 5 minutes
- ✅ Clean workspace management
- ✅ Detailed logging and debugging
- ✅ Proper error handling
- ✅ Build artifact generation
- ✅ Webhook support for instant triggering
