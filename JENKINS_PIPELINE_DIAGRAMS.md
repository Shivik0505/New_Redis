# 📊 Jenkins Pipeline Visualization Diagrams

This document explains the three comprehensive diagrams created to visualize the Redis Infrastructure Jenkins Pipeline using Python's `diagrams` library.

## 🎯 Overview

The diagrams provide a complete visual representation of:
1. **Jenkins CI/CD Pipeline Flow** - High-level pipeline overview
2. **Detailed Pipeline Stages** - Step-by-step execution flow
3. **AWS Infrastructure Architecture** - Deployed infrastructure components

---

## 📈 Diagram 1: Jenkins Pipeline Overview
**File:** `jenkins_pipeline_diagram.png`

### Purpose
Shows the complete CI/CD pipeline from source control to Redis deployment, including AWS infrastructure components.

### Key Components

#### Source Control
- **GitHub Repository** with SCM polling (every 5 minutes)
- Automatic trigger on code changes

#### Jenkins Pipeline Stages
1. **Clone Repository** - Checkout code and display commit information
2. **Pre-flight Checks** - Validate AWS credentials and service limits
3. **Setup Key Pair** - Create/manage SSH key pairs
4. **Terraform Plan** - Initialize, validate, and plan infrastructure
5. **Terraform Apply** - Deploy AWS resources
6. **Wait for Infrastructure** - Ensure instances are ready
7. **Ansible Configuration** - Install and configure Redis
8. **Post-Deployment Verification** - Validate deployment
9. **Generate Artifacts** - Create connection guides and outputs

#### AWS Infrastructure
- **VPC** with public and private subnets
- **Bastion Host** for secure access
- **3 Redis Nodes** in private subnets across AZs
- **NAT Gateway** for outbound internet access

#### Deployment Outputs
- Connection guide with SSH commands
- Private SSH key for access
- Terraform state outputs

### Flow Highlights
- **Blue arrows**: Infrastructure deployment
- **Green arrows**: Ansible configuration via bastion host
- **Dashed lines**: Network proxy connections

---

## 🔄 Diagram 2: Detailed Pipeline Flow
**File:** `jenkins_detailed_flow.png`

### Purpose
Provides granular view of each pipeline stage, including conditional logic and error handling.

### Detailed Stage Breakdown

#### Stage 1: Clone Repository
- Checkout SCM from GitHub
- Display commit ID, message, and author
- Set up workspace

#### Stage 2: Pre-flight Checks
- Validate AWS credentials using `aws sts get-caller-identity`
- Check AWS service limits and quotas
- Verify existing resources to avoid conflicts

#### Stage 3: Setup Key Pair
- Check if key pair exists in AWS
- Create new key or recreate if requested
- Update Terraform configurations with key name
- Set proper file permissions (400)

#### Stage 4: Terraform Plan
- `terraform init` - Initialize working directory
- `terraform validate` - Validate configuration syntax
- `terraform plan` - Generate execution plan

#### Stage 5: Terraform Apply (Conditional)
- Only runs if `autoApprove` parameter is true
- `terraform apply` - Deploy infrastructure
- `terraform output` - Extract deployment information

#### Stage 6: Wait for Infrastructure
- Wait for EC2 instances to reach running state
- Test SSH connectivity to bastion host
- Ensure all services are ready

#### Stage 7: Ansible Configuration
- Create dynamic inventory with bastion host configuration
- Test SSH connectivity through bastion
- Run Ansible playbook to install Redis
- Verify Redis installation with `redis-cli ping`

#### Stage 8: Post-Deployment Verification
- Verify all EC2 instances are running
- Check VPC and networking components
- Validate security group configurations

#### Stage 9: Generate Artifacts
- Create connection guide with SSH commands
- Archive SSH private key
- Save Terraform outputs for reference

### Error Handling
- **Red dashed arrows**: Error paths leading to diagnostics
- **Failure Diagnostics**: Analyze what went wrong
- **Cleanup Resources**: Remove partially created resources
- **Conditional Paths**: Skip stages based on parameters

---

## 🏗️ Diagram 3: AWS Infrastructure Architecture
**File:** `redis_infrastructure_architecture.png`

### Purpose
Detailed view of the AWS infrastructure components deployed by the pipeline.

### Infrastructure Components

#### VPC Configuration
- **VPC CIDR**: 10.0.0.0/16
- **Region**: ap-south-1
- **Multi-AZ deployment** across 3 availability zones

#### Public Subnet (10.0.1.0/24)
- **Bastion Host**: 
  - Instance: t3.micro
  - Public IP: 13.203.223.190
  - Purpose: Secure SSH access point
  - Security Group: SSH (22), HTTP (80), ICMP

#### Private Subnets
- **Redis Node 1** (AZ: ap-south-1a, 10.0.2.0/24)
  - Private IP: 10.0.2.234
  - Instance: t3.micro
  - Redis Port: 6379 (cluster enabled)

- **Redis Node 2** (AZ: ap-south-1b, 10.0.3.0/24)
  - Private IP: 10.0.3.179
  - Instance: t3.micro
  - Redis Port: 6379 (cluster enabled)

- **Redis Node 3** (AZ: ap-south-1c, 10.0.4.0/24)
  - Private IP: 10.0.4.119
  - Instance: t3.micro
  - Redis Port: 6379 (cluster enabled)

#### Network Components
- **Internet Gateway**: Public internet access
- **NAT Gateway**: Outbound internet for private instances
- **Elastic IP**: Static IP for NAT Gateway

#### Security Groups
- **Public Security Group**:
  - SSH (22): 0.0.0.0/0
  - HTTP (80): 0.0.0.0/0
  - ICMP: All traffic

- **Private Security Group**:
  - Redis (6379): 0.0.0.0/0
  - Redis Cluster (16379-16384): All traffic
  - SSH (22): VPC CIDR only

#### Route Tables
- **Public Route Table**:
  - 0.0.0.0/0 → Internet Gateway
  - 10.0.0.0/16 → Local

- **Private Route Table**:
  - 0.0.0.0/0 → NAT Gateway
  - 10.0.0.0/16 → Local

### Network Flow
- **Blue arrows**: Direct SSH access from internet
- **Green dashed arrows**: SSH proxy through bastion
- **Orange arrows**: Outbound internet traffic via NAT
- **Red dotted arrows**: Redis cluster communication
- **Gray lines**: Security group and route table associations

---

## 🛠️ Technical Implementation

### Diagram Creation Tools
- **Python Library**: `diagrams` (v0.24.4)
- **Rendering Engine**: Graphviz
- **Output Format**: PNG images
- **Virtual Environment**: Isolated Python environment

### Code Structure
```python
# Main components used
from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.ci import Jenkins
from diagrams.aws.compute import EC2
from diagrams.aws.network import VPC, NATGateway
from diagrams.onprem.inmemory import Redis
```

### Diagram Features
- **Clusters**: Logical grouping of related components
- **Edges**: Directional flow with labels and styling
- **Color Coding**: Different colors for different types of connections
- **Styling**: Dashed, dotted, and solid lines for different purposes

---

## 📚 Usage Instructions

### Viewing the Diagrams
1. **jenkins_pipeline_diagram.png** - Start here for overall understanding
2. **jenkins_detailed_flow.png** - Dive deep into stage-by-stage flow
3. **redis_infrastructure_architecture.png** - Understand the deployed infrastructure

### Regenerating Diagrams
```bash
# Activate virtual environment
source diagram_env/bin/activate

# Run diagram creation scripts
python create_jenkins_diagram.py
python create_detailed_flow_diagram.py
python create_infrastructure_diagram.py
```

### Customization
- Modify the Python scripts to add/remove components
- Change colors, labels, and styling as needed
- Add new clusters or connections for additional features

---

## 🎯 Key Insights from Diagrams

### Pipeline Efficiency
- **Automated Triggers**: SCM polling eliminates manual intervention
- **Conditional Execution**: Stages skip when not needed
- **Error Recovery**: Comprehensive error handling and cleanup

### Infrastructure Security
- **Bastion Host Pattern**: Secure access to private resources
- **Multi-AZ Deployment**: High availability across zones
- **Security Groups**: Principle of least privilege

### Redis Clustering
- **3-Node Setup**: Optimal for development/testing
- **Cross-AZ Communication**: Cluster nodes can communicate
- **Port Configuration**: Standard Redis and cluster ports

### Operational Excellence
- **Artifact Generation**: Connection guides and keys
- **Verification Steps**: Multiple validation points
- **Documentation**: Automated guide creation

---

## 🔄 Continuous Improvement

### Potential Enhancements
1. **Add monitoring stages** for CloudWatch integration
2. **Include backup procedures** in the pipeline
3. **Add security scanning** stages
4. **Implement blue-green deployment** patterns

### Diagram Updates
- Update diagrams when pipeline changes
- Add new AWS services as they're integrated
- Include monitoring and alerting components

---

## 📞 Support and Maintenance

### Troubleshooting Diagrams
- Ensure Graphviz is installed: `brew install graphviz`
- Check Python virtual environment activation
- Verify all required packages are installed

### Updating Infrastructure
- Modify Terraform configurations
- Update diagram scripts to reflect changes
- Regenerate diagrams after infrastructure updates

---

**Created with ❤️ using Python Diagrams Library**
*Last Updated: June 26, 2025*
