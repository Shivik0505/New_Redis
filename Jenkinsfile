pipeline {
    agent any

    // Enable SCM polling - check for changes every 5 minutes
    triggers {
        pollSCM('H/5 * * * *')
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
        PATH = "/opt/homebrew/bin:/usr/local/bin:${env.PATH}"
    }

    stages {

        stage('Clone Repository') {
            steps {
                echo "=== Cloning Repository ==="
                checkout scm
                
                // Display commit information
                script {
                    def commitId = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
                    def commitMsg = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
                    def commitAuthor = sh(returnStdout: true, script: 'git log -1 --pretty=%an').trim()
                    
                    echo "Commit ID: ${commitId}"
                    echo "Commit Message: ${commitMsg}"
                    echo "Commit Author: ${commitAuthor}"
                }
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
                        echo "Checking AWS credentials..."
                        aws sts get-caller-identity
                        
                        echo "Checking AWS service limits..."
                        aws ec2 describe-account-attributes --attribute-names supported-platforms --region $AWS_DEFAULT_REGION
                        
                        echo "Checking existing resources..."
                        aws ec2 describe-vpcs --region $AWS_DEFAULT_REGION --query 'Vpcs[?Tags[?Key==`Name` && Value==`redis-VPC`]]' --output table || true
                    '''
                }
            }
        }

        stage('Setup Key Pair') {
            when {
                expression { return params.action == 'apply' }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    script {
                        sh '''
                            echo "=== Key Pair Setup ==="
                            echo "Using key pair name: $KEY_PAIR_NAME"
                            
                            # Check if key pair exists
                            if aws ec2 describe-key-pairs --key-names "$KEY_PAIR_NAME" --region $AWS_DEFAULT_REGION >/dev/null 2>&1; then
                                echo "Key pair '$KEY_PAIR_NAME' exists in AWS"
                                
                                if [ "$recreateKeyPair" = "true" ]; then
                                    echo "Recreating key pair as requested..."
                                    aws ec2 delete-key-pair --key-name "$KEY_PAIR_NAME" --region $AWS_DEFAULT_REGION
                                    echo "Creating new key pair '$KEY_PAIR_NAME'..."
                                    aws ec2 create-key-pair --key-name "$KEY_PAIR_NAME" --region $AWS_DEFAULT_REGION --query 'KeyMaterial' --output text > "${KEY_PAIR_NAME}.pem"
                                    chmod 400 "${KEY_PAIR_NAME}.pem"
                                    echo "New key pair created successfully!"
                                else
                                    echo "Using existing key pair. Note: .pem file not available in Jenkins."
                                fi
                            else
                                echo "Creating new key pair '$KEY_PAIR_NAME'..."
                                aws ec2 create-key-pair --key-name "$KEY_PAIR_NAME" --region $AWS_DEFAULT_REGION --query 'KeyMaterial' --output text > "${KEY_PAIR_NAME}.pem"
                                chmod 400 "${KEY_PAIR_NAME}.pem"
                                echo "Key pair created successfully!"
                            fi
                            
                            # Update Terraform variable if different from default
                            if [ "$KEY_PAIR_NAME" != "redis-infra-key" ]; then
                                echo "Updating Terraform configuration with new key pair name..."
                                sed -i "s/default = \\".*\\"/default = \\"$KEY_PAIR_NAME\\"/" terraform/instances/variable.tf
                                echo "Terraform configuration updated"
                            fi
                        '''
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        echo "=== Terraform Init ==="
                        cd terraform/
                        terraform init -input=false

                        echo "=== Terraform Validate ==="
                        terraform validate

                        echo "=== Terraform Plan ==="
                        terraform plan -input=false -out=tfplan -detailed-exitcode || {
                            exit_code=$?
                            if [ $exit_code -eq 2 ]; then
                                echo "Changes detected in plan"
                                exit 0
                            else
                                echo "Plan failed with exit code $exit_code"
                                exit $exit_code
                            fi
                        }
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'terraform/tfplan', allowEmptyArchive: true
                }
            }
        }

        stage('Terraform Apply/Destroy') {
            when {
                expression { return params.autoApprove }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    script {
                        if (params.action == 'apply') {
                            sh '''
                                echo "=== Terraform Apply ==="
                                cd terraform/
                                terraform apply -input=false tfplan
                                
                                echo "=== Deployment Summary ==="
                                terraform output -json > ../terraform-outputs.json
                                terraform output
                            '''
                        } else if (params.action == 'destroy') {
                            sh '''
                                echo "=== Terraform Destroy ==="
                                cd terraform/
                                terraform destroy -input=false --auto-approve
                                
                                echo "=== Cleanup Key Pair ==="
                                if aws ec2 describe-key-pairs --key-names "$KEY_PAIR_NAME" --region $AWS_DEFAULT_REGION >/dev/null 2>&1; then
                                    echo "Deleting key pair '$KEY_PAIR_NAME'..."
                                    aws ec2 delete-key-pair --key-name "$KEY_PAIR_NAME" --region $AWS_DEFAULT_REGION
                                    echo "Key pair deleted"
                                fi
                            '''
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        if (params.action == 'apply' && fileExists('terraform-outputs.json')) {
                            archiveArtifacts artifacts: 'terraform-outputs.json', allowEmptyArchive: true
                        }
                    }
                }
            }
        }

        stage('Wait for Infrastructure') {
            when {
                allOf {
                    expression { return params.autoApprove }
                    expression { return params.action == 'apply' }
                }
            }
            steps {
                echo "=== Waiting for infrastructure to be ready ==="
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        echo "Waiting for instances to be running..."
                        sleep 60
                        
                        echo "Checking instance status..."
                        aws ec2 describe-instances \
                            --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=redis-*" \
                            --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`].Value|[0],State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}' \
                            --output table --region $AWS_DEFAULT_REGION
                        
                        echo "Waiting additional time for SSH to be ready..."
                        sleep 30
                    '''
                }
            }
        }

        stage('Run Ansible Configuration') {
            when {
                allOf {
                    expression { return params.autoApprove }
                    expression { return params.action == 'apply' }
                    expression { return !params.skipAnsible }
                }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        echo "=== Running Ansible Configuration ==="
                        
                        # Check if key file exists (created in this pipeline run)
                        if [ -f "${KEY_PAIR_NAME}.pem" ]; then
                            chmod 400 "${KEY_PAIR_NAME}.pem"
                            export ANSIBLE_HOST_KEY_CHECKING=False
                            export ANSIBLE_SSH_RETRIES=3
                            export ANSIBLE_TIMEOUT=30
                            
                            echo "Running Ansible with ${KEY_PAIR_NAME}.pem"
                            
                            # Update Ansible configuration to use the correct key
                            sed -i "s/redis-demo-key/${KEY_PAIR_NAME}/g" aws_ec2.yaml || true
                            sed -i "s/redis-infra-key/${KEY_PAIR_NAME}/g" playbook.yml || true
                            
                            # Test Ansible inventory
                            echo "Testing Ansible inventory..."
                            ansible-inventory -i aws_ec2.yaml --list
                            
                            # Run Ansible playbook with retries
                            echo "Running Ansible playbook..."
                            ansible-playbook -i aws_ec2.yaml playbook.yml --private-key="${KEY_PAIR_NAME}.pem" -v || {
                                echo "First attempt failed, retrying in 30 seconds..."
                                sleep 30
                                ansible-playbook -i aws_ec2.yaml playbook.yml --private-key="${KEY_PAIR_NAME}.pem" -v
                            }
                        else
                            echo "⚠️  Key file ${KEY_PAIR_NAME}.pem not found."
                            echo "This might happen if using an existing key pair."
                            echo "Ansible configuration skipped. You can run it manually later."
                            echo ""
                            echo "To run Ansible manually:"
                            echo "1. Download the key pair from AWS or use your existing .pem file"
                            echo "2. Run: ansible-playbook -i aws_ec2.yaml playbook.yml --private-key=your-key.pem"
                        fi
                    '''
                }
            }
        }

        stage('Post-Deployment Verification') {
            when {
                allOf {
                    expression { return params.autoApprove }
                    expression { return params.action == 'apply' }
                }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        echo "=== Post-Deployment Verification ==="
                        
                        echo "Checking deployed instances..."
                        aws ec2 describe-instances \
                            --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=redis-*" \
                            --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`].Value|[0],State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress,InstanceType:InstanceType}' \
                            --output table --region $AWS_DEFAULT_REGION
                        
                        echo ""
                        echo "Checking VPC and networking..."
                        aws ec2 describe-vpcs \
                            --filters "Name=tag:Name,Values=redis-VPC" \
                            --query 'Vpcs[].{VpcId:VpcId,CidrBlock:CidrBlock,State:State}' \
                            --output table --region $AWS_DEFAULT_REGION
                        
                        echo ""
                        echo "Checking security groups..."
                        aws ec2 describe-security-groups \
                            --filters "Name=group-name,Values=*redis*" \
                            --query 'SecurityGroups[].{GroupName:GroupName,GroupId:GroupId,Description:Description}' \
                            --output table --region $AWS_DEFAULT_REGION
                        
                        echo ""
                        echo "=== Deployment Complete! ==="
                        echo "Key Pair Used: $KEY_PAIR_NAME"
                        echo "Region: $AWS_DEFAULT_REGION"
                        echo "Deployment Time: $(date)"
                    '''
                }
            }
        }

        stage('Generate Connection Guide') {
            when {
                allOf {
                    expression { return params.autoApprove }
                    expression { return params.action == 'apply' }
                }
            }
            steps {
                script {
                    sh '''
                        echo "=== Connection Guide ==="
                        
                        # Get public IP from terraform output
                        cd terraform/
                        PUBLIC_IP=$(terraform output -raw public-instance-ip 2>/dev/null || echo "Not available")
                        PRIVATE_IP_1=$(terraform output -raw private-instance1-ip 2>/dev/null || echo "Not available")
                        PRIVATE_IP_2=$(terraform output -raw private-instance2-ip 2>/dev/null || echo "Not available")
                        PRIVATE_IP_3=$(terraform output -raw private-instance3-ip 2>/dev/null || echo "Not available")
                        
                        cd ..
                        
                        # Create connection guide
                        cat > connection-guide.txt << EOF
Redis Infrastructure Connection Guide
=====================================

Deployment Details:
- Key Pair: ${KEY_PAIR_NAME}
- Region: ${AWS_DEFAULT_REGION}
- Deployment Time: $(date)

Instance Details:
- Bastion Host (Public): ${PUBLIC_IP}
- Redis Node 1 (Private): ${PRIVATE_IP_1}
- Redis Node 2 (Private): ${PRIVATE_IP_2}
- Redis Node 3 (Private): ${PRIVATE_IP_3}

Connection Commands:
1. Connect to Bastion Host:
   ssh -i ${KEY_PAIR_NAME}.pem ubuntu@${PUBLIC_IP}

2. Connect to Redis Nodes (via Bastion):
   ssh -i ${KEY_PAIR_NAME}.pem -J ubuntu@${PUBLIC_IP} ubuntu@${PRIVATE_IP_1}
   ssh -i ${KEY_PAIR_NAME}.pem -J ubuntu@${PUBLIC_IP} ubuntu@${PRIVATE_IP_2}
   ssh -i ${KEY_PAIR_NAME}.pem -J ubuntu@${PUBLIC_IP} ubuntu@${PRIVATE_IP_3}

3. Configure Redis Cluster:
   # On each Redis node:
   sudo apt update && sudo apt install redis-server -y
   
   # Edit Redis config:
   sudo nano /etc/redis/redis.conf
   # Uncomment: cluster-enabled yes
   # Uncomment: cluster-config-file nodes.conf
   # Uncomment: cluster-node-timeout 5000
   
   # Restart Redis:
   sudo systemctl restart redis-server
   
   # Create cluster (run from any node):
   redis-cli --cluster create ${PRIVATE_IP_1}:6379 ${PRIVATE_IP_2}:6379 ${PRIVATE_IP_3}:6379 --cluster-replicas 0

Next Steps:
- Download the ${KEY_PAIR_NAME}.pem file from Jenkins artifacts
- Use the connection commands above to access your infrastructure
- Configure Redis clustering as needed
- Set up monitoring and backups

EOF
                        
                        echo "Connection guide created:"
                        cat connection-guide.txt
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'connection-guide.txt', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        always {
            script {
                // Archive key file if created (for download)
                if (fileExists("${params.keyPairName}.pem")) {
                    archiveArtifacts artifacts: "${params.keyPairName}.pem", allowEmptyArchive: true
                }
                
                // Archive Terraform state files
                if (fileExists("terraform/terraform.tfstate")) {
                    archiveArtifacts artifacts: 'terraform/terraform.tfstate*', allowEmptyArchive: true
                }
            }
            
            // Clean workspace but keep important files
            sh '''
                # Keep important files but clean temporary ones
                find . -name "*.log" -delete || true
                find . -name ".terraform" -type d -exec rm -rf {} + || true
            '''
        }
        
        failure {
            echo '❌ Pipeline failed!'
            script {
                sh '''
                    echo "=== Failure Diagnostics ==="
                    echo "Checking AWS resources that might need cleanup..."
                    
                    # Check for any resources that might have been partially created
                    aws ec2 describe-instances --region $AWS_DEFAULT_REGION --filters "Name=tag:Name,Values=redis-*" --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`].Value|[0],State:State.Name,InstanceId:InstanceId}' --output table || true
                    
                    echo "Check the logs above for specific error details."
                    echo "You may need to run cleanup manually if resources were partially created."
                '''
            }
        }
        
        success {
            echo '✅ Pipeline completed successfully!'
            echo "Redis infrastructure deployed with key pair: ${params.keyPairName}"
            echo "Check the 'Generate Connection Guide' stage output for connection details."
            echo "Download the connection-guide.txt and ${params.keyPairName}.pem files from Jenkins artifacts."
        }
    }
}
