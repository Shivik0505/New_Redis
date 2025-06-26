pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Select the action to perform')
        string(name: 'keyPairName', defaultValue: 'redis-demo-key', description: 'AWS Key Pair name to use')
        booleanParam(name: 'recreateKeyPair', defaultValue: false, description: 'Force recreate key pair if it exists?')
    }

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        KEY_PAIR_NAME = "${params.keyPairName}"
    }

    stages {

        stage('Clone Repository') {
            steps {
                git url: 'https://github.com/JayLikhare316/redisdemo.git', branch: 'master'
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
                            if [ "$KEY_PAIR_NAME" != "redis-demo-key" ]; then
                                echo "Updating Terraform configuration with new key pair name..."
                                sed -i "s/default = \\".*\\"/default = \\"$KEY_PAIR_NAME\\"/" terraform/instances/variable.tf
                                echo "Terraform configuration updated"
                            fi
                        '''
                    }
                }
            }
        }

        stage('Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        echo "=== Terraform Init ==="
                        cd terraform/
                        terraform init

                        echo "=== Terraform Validate ==="
                        terraform validate

                        echo "=== Terraform Plan ==="
                        terraform plan -out=tfplan
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'terraform/tfplan', allowEmptyArchive: true
                }
            }
        }

        stage('Apply/Destroy') {
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
                                terraform apply tfplan
                                
                                echo "=== Deployment Summary ==="
                                terraform output
                            '''
                        } else if (params.action == 'destroy') {
                            sh '''
                                echo "=== Terraform Destroy ==="
                                cd terraform/
                                terraform destroy --auto-approve
                                
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
                sleep time: 90, unit: 'SECONDS'
            }
        }

        stage('Run Ansible Playbook') {
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
                        echo "=== Running Ansible Playbook ==="
                        
                        # Check if key file exists (created in this pipeline run)
                        if [ -f "${KEY_PAIR_NAME}.pem" ]; then
                            chmod 400 "${KEY_PAIR_NAME}.pem"
                            export ANSIBLE_HOST_KEY_CHECKING=False
                            echo "Running Ansible with ${KEY_PAIR_NAME}.pem"
                            
                            # Update Ansible configuration to use the correct key
                            sed -i "s/redis-demo-key/${KEY_PAIR_NAME}/g" aws_ec2.yaml
                            sed -i "s/redis-demo-key/${KEY_PAIR_NAME}/g" playbook.yml
                            
                            # Wait a bit more for instances to be fully ready
                            echo "Waiting additional time for instances to be fully ready..."
                            sleep 30
                            
                            # Run Ansible playbook
                            ansible-playbook -i aws_ec2.yaml playbook.yml --private-key="${KEY_PAIR_NAME}.pem" -v
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

        stage('Deployment Verification') {
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
                        echo "=== Deployment Verification ==="
                        
                        echo "Checking deployed instances..."
                        aws ec2 describe-instances \
                            --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=redis-*" \
                            --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`].Value|[0],State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}' \
                            --output table --region $AWS_DEFAULT_REGION
                        
                        echo ""
                        echo "=== Deployment Complete! ==="
                        echo "Key Pair Used: $KEY_PAIR_NAME"
                        echo "Region: $AWS_DEFAULT_REGION"
                        echo ""
                        echo "Next steps:"
                        echo "1. Connect to bastion host: ssh -i ${KEY_PAIR_NAME}.pem ubuntu@<public-ip>"
                        echo "2. Access Redis nodes through bastion host"
                        echo "3. Configure Redis cluster if Ansible step was skipped"
                    '''
                }
            }
        }
    }

    post {
        always {
            // Archive key file if created (for download)
            script {
                if (fileExists("${params.keyPairName}.pem")) {
                    archiveArtifacts artifacts: "${params.keyPairName}.pem", allowEmptyArchive: true
                }
            }
            cleanWs()
        }
        failure {
            echo 'Pipeline failed!'
            // Add notification logic here if needed
        }
        success {
            echo 'Pipeline completed successfully!'
            echo "Redis infrastructure deployed with key pair: ${params.keyPairName}"
        }
    }
}
