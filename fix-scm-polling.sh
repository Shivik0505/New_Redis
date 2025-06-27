#!/bin/bash

# SCM Polling Fix Script for Jenkins Pipeline
# This script helps diagnose and fix SCM polling issues

set -e

echo "🔧 Jenkins SCM Polling Fix Script"
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

# Check Git repository configuration
check_git_config() {
    echo -e "\n${BLUE}1. Checking Git Repository Configuration${NC}"
    echo "========================================"
    
    if [ -d ".git" ]; then
        print_status "SUCCESS" "Git repository found"
        
        # Check remote configuration
        local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [ -n "$remote_url" ]; then
            print_status "SUCCESS" "Remote URL: $remote_url"
            
            # Check if it's HTTPS or SSH
            if [[ "$remote_url" == https://* ]]; then
                print_status "INFO" "Using HTTPS remote (recommended for Jenkins)"
            elif [[ "$remote_url" == git@* ]]; then
                print_status "WARNING" "Using SSH remote (may need SSH key configuration in Jenkins)"
            fi
        else
            print_status "ERROR" "No remote URL configured"
            return 1
        fi
        
        # Check current branch
        local current_branch=$(git branch --show-current 2>/dev/null || echo "")
        if [ -n "$current_branch" ]; then
            print_status "SUCCESS" "Current branch: $current_branch"
        else
            print_status "WARNING" "Could not determine current branch"
        fi
        
        # Check if there are uncommitted changes
        if git diff-index --quiet HEAD --; then
            print_status "SUCCESS" "Working directory is clean"
        else
            print_status "WARNING" "Working directory has uncommitted changes"
            echo "Uncommitted files:"
            git status --porcelain
        fi
        
    else
        print_status "ERROR" "Not a git repository"
        return 1
    fi
}

# Test Git connectivity
test_git_connectivity() {
    echo -e "\n${BLUE}2. Testing Git Connectivity${NC}"
    echo "============================"
    
    print_status "INFO" "Testing git fetch..."
    if git fetch --dry-run origin 2>/dev/null; then
        print_status "SUCCESS" "Git fetch test successful"
    else
        print_status "ERROR" "Git fetch test failed"
        echo "This could indicate:"
        echo "  - Network connectivity issues"
        echo "  - Authentication problems"
        echo "  - Repository access permissions"
        return 1
    fi
    
    print_status "INFO" "Checking for new commits..."
    local local_commit=$(git rev-parse HEAD)
    local remote_commit=$(git rev-parse origin/$(git branch --show-current) 2>/dev/null || echo "")
    
    if [ "$local_commit" = "$remote_commit" ]; then
        print_status "SUCCESS" "Local and remote are in sync"
    else
        print_status "WARNING" "Local and remote commits differ"
        echo "Local:  $local_commit"
        echo "Remote: $remote_commit"
    fi
}

# Generate Jenkins SCM configuration
generate_jenkins_scm_config() {
    echo -e "\n${BLUE}3. Generating Jenkins SCM Configuration${NC}"
    echo "======================================"
    
    local repo_url=$(git remote get-url origin)
    local branch=$(git branch --show-current)
    
    cat > jenkins-scm-config.xml << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Redis Infrastructure Pipeline with SCM Polling</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.BooleanParameterDefinition>
          <name>autoApprove</name>
          <description>Automatically run apply after generating plan?</description>
          <defaultValue>true</defaultValue>
        </hudson.model.BooleanParameterDefinition>
        <hudson.model.ChoiceParameterDefinition>
          <name>action</name>
          <description>Select the action to perform</description>
          <choices>
            <string>apply</string>
            <string>destroy</string>
          </choices>
        </hudson.model.ChoiceParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.92">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>$repo_url</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/$branch</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

    print_status "SUCCESS" "Jenkins SCM configuration generated: jenkins-scm-config.xml"
    echo "Repository URL: $repo_url"
    echo "Branch: $branch"
}

# Create webhook setup instructions
create_webhook_instructions() {
    echo -e "\n${BLUE}4. GitHub Webhook Setup Instructions${NC}"
    echo "===================================="
    
    local repo_url=$(git remote get-url origin)
    local repo_name=$(basename "$repo_url" .git)
    local github_url="https://github.com/$(echo "$repo_url" | sed 's/.*github.com[:/]//' | sed 's/.git$//')"
    
    cat > webhook-setup-instructions.md << EOF
# GitHub Webhook Setup for Jenkins SCM Polling

## Automatic Webhook Setup (Recommended)

### Step 1: Configure Jenkins GitHub Plugin
1. Go to Jenkins → Manage Jenkins → Configure System
2. Find "GitHub" section
3. Add GitHub Server:
   - Name: \`GitHub\`
   - API URL: \`https://api.github.com\`
   - Credentials: Add GitHub personal access token

### Step 2: Enable GitHub Hook Trigger
1. In your Jenkins job configuration
2. Under "Build Triggers"
3. Check "GitHub hook trigger for GITScm polling"

## Manual Webhook Setup

### Step 1: Go to GitHub Repository Settings
Repository: $github_url
1. Click "Settings" tab
2. Click "Webhooks" in left sidebar
3. Click "Add webhook"

### Step 2: Configure Webhook
- **Payload URL**: \`http://YOUR_JENKINS_URL/github-webhook/\`
- **Content type**: \`application/json\`
- **Secret**: (optional, but recommended)
- **Events**: Select "Just the push event"
- **Active**: ✅ Checked

### Step 3: Test Webhook
1. Make a commit and push to repository
2. Check webhook deliveries in GitHub
3. Verify Jenkins job is triggered

## SCM Polling Configuration

### Current Configuration:
- **Polling Schedule**: \`H/5 * * * *\` (every 5 minutes)
- **Repository**: $repo_url
- **Branch**: $(git branch --show-current)

### Alternative Polling Schedules:
- Every minute: \`* * * * *\`
- Every 2 minutes: \`H/2 * * * *\`
- Every 10 minutes: \`H/10 * * * *\`
- Every hour: \`H * * * *\`

## Troubleshooting SCM Polling

### Common Issues:
1. **No polling happening**:
   - Check Jenkins system log for SCM polling messages
   - Verify cron syntax in polling schedule
   - Ensure repository is accessible

2. **Polling but not triggering builds**:
   - Check if there are actual changes to poll
   - Verify branch configuration matches
   - Check Jenkins user permissions

3. **Authentication issues**:
   - For HTTPS: Use personal access token
   - For SSH: Configure SSH keys in Jenkins

### Debug Commands:
\`\`\`bash
# Check recent commits
git log --oneline -10

# Test git fetch
git fetch --dry-run origin

# Check remote configuration
git remote -v
\`\`\`

## Jenkins Job Configuration

### Required Jenkins Plugins:
- Git Plugin
- GitHub Plugin
- Pipeline Plugin

### Job Configuration Steps:
1. Create new Pipeline job
2. Under "Pipeline" section:
   - Definition: "Pipeline script from SCM"
   - SCM: "Git"
   - Repository URL: $repo_url
   - Branch: */$(git branch --show-current)
   - Script Path: Jenkinsfile

3. Under "Build Triggers":
   - Check "Poll SCM"
   - Schedule: \`H/5 * * * *\`
   - OR check "GitHub hook trigger for GITScm polling"

## Testing the Setup

### Test SCM Polling:
1. Make a small change to README.md
2. Commit and push: \`git add . && git commit -m "test scm polling" && git push\`
3. Wait 5 minutes or check Jenkins immediately
4. Verify build is triggered

### Test Webhook (if configured):
1. Make a change and push
2. Check GitHub webhook deliveries
3. Verify Jenkins build starts immediately
EOF

    print_status "SUCCESS" "Webhook setup instructions created: webhook-setup-instructions.md"
}

# Create improved Jenkinsfile with better SCM handling
create_improved_jenkinsfile() {
    echo -e "\n${BLUE}5. Creating Improved Jenkinsfile for SCM${NC}"
    echo "======================================="
    
    cat > Jenkinsfile_SCM_Fixed << 'EOF'
pipeline {
    agent any

    // SCM Polling Configuration
    triggers {
        // Poll SCM every 5 minutes for changes
        pollSCM('H/5 * * * *')
        
        // Alternative: Use webhook trigger (recommended)
        // githubPush()
    }

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: true, description: 'Automatically run apply after generating plan?')
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Select the action to perform')
        string(name: 'keyPairName', defaultValue: 'redis-infra-key', description: 'AWS Key Pair name to use')
        booleanParam(name: 'recreateKeyPair', defaultValue: false, description: 'Force recreate key pair if it exists?')
        booleanParam(name: 'skipAnsible', defaultValue: false, description: 'Skip Ansible configuration step?')
    }

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        KEY_PAIR_NAME = "${params.keyPairName}"
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }

    stages {
        stage('SCM Checkout & Validation') {
            steps {
                script {
                    echo "=== SCM Checkout & Validation ==="
                    
                    // Explicit checkout with detailed logging
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/master']],
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [
                            [$class: 'CleanBeforeCheckout'],
                            [$class: 'CloneOption', depth: 1, noTags: false, reference: '', shallow: true]
                        ],
                        submoduleCfg: [],
                        userRemoteConfigs: [[url: 'https://github.com/Shivik0505/New_Redis.git']]
                    ])
                    
                    // Display SCM information
                    def gitCommit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
                    def gitBranch = sh(returnStdout: true, script: 'git rev-parse --abbrev-ref HEAD').trim()
                    def gitAuthor = sh(returnStdout: true, script: 'git log -1 --pretty=%an').trim()
                    def gitMessage = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
                    def gitTimestamp = sh(returnStdout: true, script: 'git log -1 --pretty=%ci').trim()
                    
                    echo "✅ SCM Checkout Successful"
                    echo "📋 Git Information:"
                    echo "   Commit: ${gitCommit}"
                    echo "   Branch: ${gitBranch}"
                    echo "   Author: ${gitAuthor}"
                    echo "   Message: ${gitMessage}"
                    echo "   Timestamp: ${gitTimestamp}"
                    
                    // Check for changes that should trigger build
                    def changedFiles = sh(returnStdout: true, script: 'git diff --name-only HEAD~1 HEAD || echo "No previous commit"').trim()
                    if (changedFiles && changedFiles != "No previous commit") {
                        echo "📝 Changed files in this commit:"
                        changedFiles.split('\n').each { file ->
                            echo "   - ${file}"
                        }
                    }
                    
                    // Validate repository structure
                    def requiredFiles = ['terraform/', 'ansible/', 'Jenkinsfile', 'README.md']
                    requiredFiles.each { file ->
                        if (fileExists(file)) {
                            echo "✅ Required file/directory found: ${file}"
                        } else {
                            error "❌ Required file/directory missing: ${file}"
                        }
                    }
                }
            }
        }

        stage('Environment Setup') {
            steps {
                echo "=== Environment Setup ==="
                script {
                    // Display build trigger information
                    def buildCause = currentBuild.getBuildCauses()
                    echo "🔄 Build Trigger Information:"
                    buildCause.each { cause ->
                        echo "   Type: ${cause.getClass().getSimpleName()}"
                        if (cause.hasProperty('shortDescription')) {
                            echo "   Description: ${cause.shortDescription}"
                        }
                    }
                    
                    // Check if this is an SCM-triggered build
                    def scmTriggered = buildCause.any { it.getClass().getSimpleName().contains('SCM') }
                    def webhookTriggered = buildCause.any { it.getClass().getSimpleName().contains('GitHub') }
                    
                    if (scmTriggered) {
                        echo "✅ Build triggered by SCM polling"
                    } else if (webhookTriggered) {
                        echo "✅ Build triggered by GitHub webhook"
                    } else {
                        echo "ℹ️ Build triggered manually or by other means"
                    }
                }
                
                sh '''
                    echo "Pipeline Parameters:"
                    echo "- Action: ${action}"
                    echo "- Auto Approve: ${autoApprove}"
                    echo "- Key Pair: ${keyPairName}"
                    echo "- Skip Ansible: ${skipAnsible}"
                    echo "- AWS Region: ${AWS_DEFAULT_REGION}"
                    echo "- Build Number: ${BUILD_NUMBER}"
                    echo "- Build URL: ${BUILD_URL}"
                '''
            }
        }

        stage('Pre-flight Checks') {
            steps {
                echo "=== Pre-flight Checks ==="
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        echo "Checking required tools..."
                        which terraform || echo "❌ Terraform not found"
                        which aws || echo "❌ AWS CLI not found"
                        which ansible || echo "❌ Ansible not found"
                        
                        echo "Testing AWS credentials..."
                        if aws sts get-caller-identity; then
                            echo "✅ AWS credentials are valid"
                        else
                            echo "❌ AWS credentials test failed"
                            exit 1
                        fi
                    '''
                }
            }
        }

        // Continue with existing pipeline stages...
        stage('Key Pair Management') {
            when {
                expression { return params.action == 'apply' }
            }
            steps {
                echo "=== Key Pair Management ==="
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        echo "Managing key pair: $KEY_PAIR_NAME"
                        
                        if aws ec2 describe-key-pairs --key-names "$KEY_PAIR_NAME" --region $AWS_DEFAULT_REGION >/dev/null 2>&1; then
                            echo "✅ Key pair '$KEY_PAIR_NAME' exists"
                            if [ "${recreateKeyPair}" = "true" ]; then
                                echo "Recreating key pair..."
                                aws ec2 delete-key-pair --key-name "$KEY_PAIR_NAME" --region $AWS_DEFAULT_REGION
                                aws ec2 create-key-pair --key-name "$KEY_PAIR_NAME" --region $AWS_DEFAULT_REGION --query 'KeyMaterial' --output text > "${KEY_PAIR_NAME}.pem"
                                chmod 400 "${KEY_PAIR_NAME}.pem"
                                echo "✅ Key pair recreated"
                            fi
                        else
                            echo "Creating new key pair..."
                            aws ec2 create-key-pair --key-name "$KEY_PAIR_NAME" --region $AWS_DEFAULT_REGION --query 'KeyMaterial' --output text > "${KEY_PAIR_NAME}.pem"
                            chmod 400 "${KEY_PAIR_NAME}.pem"
                            echo "✅ Key pair created"
                        fi
                    '''
                }
            }
        }

        stage('Terraform Operations') {
            steps {
                echo "=== Terraform Operations ==="
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    script {
                        dir('terraform') {
                            sh 'terraform init -input=false'
                            sh 'terraform validate'
                            
                            if (params.action == 'apply') {
                                sh "terraform plan -input=false -out=tfplan -var='key-name=${KEY_PAIR_NAME}'"
                                if (params.autoApprove) {
                                    sh 'terraform apply -input=false tfplan'
                                    sh 'terraform output -json > ../terraform-outputs.json'
                                    sh 'terraform output'
                                }
                            } else if (params.action == 'destroy') {
                                if (params.autoApprove) {
                                    sh "terraform destroy -input=false -var='key-name=${KEY_PAIR_NAME}' --auto-approve"
                                }
                            }
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'terraform/tfplan', allowEmptyArchive: true
                    script {
                        if (fileExists('terraform-outputs.json')) {
                            archiveArtifacts artifacts: 'terraform-outputs.json', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                // Archive key file if created
                if (fileExists("${params.keyPairName}.pem")) {
                    archiveArtifacts artifacts: "${params.keyPairName}.pem", allowEmptyArchive: true
                }
                
                // Create build summary
                def buildSummary = """
=== Build Summary ===
Build Number: ${BUILD_NUMBER}
Build URL: ${BUILD_URL}
Action: ${params.action}
Key Pair: ${params.keyPairName}
Region: ${AWS_DEFAULT_REGION}
Completion Time: ${new Date()}

Git Information:
- Commit: ${sh(returnStdout: true, script: 'git rev-parse HEAD').trim()}
- Branch: ${sh(returnStdout: true, script: 'git rev-parse --abbrev-ref HEAD').trim()}
- Author: ${sh(returnStdout: true, script: 'git log -1 --pretty=%an').trim()}
"""
                writeFile file: 'build-summary.txt', text: buildSummary
                archiveArtifacts artifacts: 'build-summary.txt', allowEmptyArchive: true
            }
        }
        
        success {
            echo '✅ Pipeline completed successfully!'
            script {
                def triggerType = currentBuild.getBuildCauses().collect { it.getClass().getSimpleName() }.join(', ')
                echo "🎉 Build triggered by: ${triggerType}"
                
                if (params.action == 'apply') {
                    echo "🚀 Redis infrastructure deployed successfully!"
                } else {
                    echo "🧹 Infrastructure destroyed successfully!"
                }
            }
        }
        
        failure {
            echo '❌ Pipeline failed!'
            echo "Check the console output above for detailed error information."
        }
    }
}
EOF

    print_status "SUCCESS" "Improved Jenkinsfile created: Jenkinsfile_SCM_Fixed"
}

# Test SCM polling functionality
test_scm_polling() {
    echo -e "\n${BLUE}6. Testing SCM Polling Functionality${NC}"
    echo "==================================="
    
    # Create a test commit to verify SCM polling
    echo "# SCM Polling Test - $(date)" > scm-test.txt
    
    print_status "INFO" "Creating test commit for SCM polling verification..."
    
    if git add scm-test.txt && git commit -m "Test SCM polling - $(date)"; then
        print_status "SUCCESS" "Test commit created"
        
        print_status "INFO" "Pushing test commit to trigger SCM polling..."
        if git push origin $(git branch --show-current); then
            print_status "SUCCESS" "Test commit pushed successfully"
            echo "✅ SCM polling should detect this change within 5 minutes"
            echo "📋 Monitor your Jenkins job for automatic triggering"
        else
            print_status "ERROR" "Failed to push test commit"
            return 1
        fi
    else
        print_status "ERROR" "Failed to create test commit"
        return 1
    fi
}

# Main execution
main() {
    echo "Starting SCM polling troubleshooting and fix..."
    echo "Current directory: $(pwd)"
    echo "Current time: $(date)"
    echo ""
    
    local exit_code=0
    
    check_git_config || exit_code=1
    test_git_connectivity || exit_code=1
    generate_jenkins_scm_config
    create_webhook_instructions
    create_improved_jenkinsfile
    
    if [ $exit_code -eq 0 ]; then
        echo -e "\n${GREEN}🎯 SCM Polling Fix Options:${NC}"
        echo "=========================="
        echo "1. 📝 Replace Jenkinsfile: mv Jenkinsfile_SCM_Fixed Jenkinsfile"
        echo "2. 🔗 Setup GitHub webhook using: webhook-setup-instructions.md"
        echo "3. ⚙️ Import Jenkins job config: jenkins-scm-config.xml"
        echo "4. 🧪 Test SCM polling with test commit"
        echo ""
        
        read -p "Do you want to test SCM polling with a test commit? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            test_scm_polling
        fi
    fi
    
    echo -e "\n${BLUE}📋 Summary${NC}"
    echo "=========="
    
    if [ $exit_code -eq 0 ]; then
        print_status "SUCCESS" "SCM polling configuration completed!"
        echo ""
        echo "✅ Files created:"
        echo "   - Jenkinsfile_SCM_Fixed (improved pipeline)"
        echo "   - jenkins-scm-config.xml (Jenkins job config)"
        echo "   - webhook-setup-instructions.md (webhook setup guide)"
        echo ""
        echo "🚀 Next steps:"
        echo "   1. Replace your current Jenkinsfile"
        echo "   2. Configure GitHub webhook (recommended)"
        echo "   3. Test the pipeline with a commit"
    else
        print_status "ERROR" "Some issues need to be resolved first"
        echo "Please fix the issues mentioned above before proceeding."
    fi
    
    return $exit_code
}

# Run the main function
main "$@"
EOF
