# Redis Infrastructure Project Documentation

## 🎯 Project Overview

This project deploys a production-ready Redis cluster infrastructure on AWS using Infrastructure as Code (IaC) principles. It combines Terraform for infrastructure provisioning, Ansible for configuration management, and Jenkins for CI/CD automation.

## 🏗️ Architecture

### Infrastructure Components
- **Custom VPC** (10.0.0.0/16) with multi-AZ deployment
- **4 EC2 Instances**: 1 Bastion Host + 3 Redis Nodes
- **Network Setup**: Public subnet for bastion, private subnets for Redis nodes
- **Security**: Dedicated security groups with Redis-specific port configurations
- **Connectivity**: NAT Gateway for internet access, VPC Peering for cross-VPC communication

### Network Layout
```
Public Subnet (10.0.1.0/24)     Private Subnets
┌─────────────────┐             ┌─────────────────┐
│  Bastion Host   │────────────▶│ Redis Node 1    │
│  (Public IP)    │             │ (10.0.2.0/24)   │
└─────────────────┘             │ ap-south-1a     │
                                └─────────────────┘
                                ┌─────────────────┐
                                │ Redis Node 2    │
                                │ (10.0.3.0/24)   │
                                │ ap-south-1b     │
                                └─────────────────┘
                                ┌─────────────────┐
                                │ Redis Node 3    │
                                │ (10.0.4.0/24)   │
                                │ ap-south-1c     │
                                └─────────────────┘
```

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Infrastructure** | Terraform | AWS resource provisioning |
| **Configuration** | Ansible | Server configuration & Redis setup |
| **CI/CD** | Jenkins | Automated deployment pipeline |
| **Application** | Node.js | Redis client application |
| **Containerization** | Docker | Application containerization |
| **Cloud Provider** | AWS | Infrastructure hosting |

## 📁 Project Structure

```
New_Redis/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Main Terraform configuration
│   ├── provider.tf           # AWS provider setup
│   ├── instances/            # EC2 instance configurations
│   ├── vpc/                  # VPC and networking
│   ├── subnets/              # Subnet configurations
│   ├── security_group/       # Security group rules
│   └── vpc_peering/          # VPC peering setup
├── ansible/                  # Configuration Management
│   ├── tasks/                # Ansible tasks
│   ├── handlers/             # Event handlers
│   ├── templates/            # Configuration templates
│   └── vars/                 # Variables
├── app.js                    # Node.js Redis client
├── redis-client.js           # Redis connection logic
├── Jenkinsfile               # CI/CD pipeline definition
├── deploy-infrastructure.sh  # Deployment automation script
├── docker-compose.yml        # Multi-container setup
├── Dockerfile               # Container definition
└── README.md                # Detailed documentation
```

## 🚀 Deployment Methods

### Method 1: Automated Script
```bash
./deploy-infrastructure.sh
```

### Method 2: Manual Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Method 3: Jenkins CI/CD
- Push code to repository
- Jenkins automatically triggers deployment
- Supports both apply and destroy operations

## ⚙️ Configuration

### Key Variables
- **Region**: ap-south-1 (Mumbai)
- **Instance Type**: t3.micro
- **Key Pair**: redis-infra-key
- **VPC CIDR**: 10.0.0.0/16

### Security Groups
- **Public SG**: SSH (22), HTTP (80), ICMP
- **Private SG**: Redis (6379), Redis Cluster (16379-16384), SSH (22)

## 🔧 Redis Cluster Setup

After infrastructure deployment:

1. **Install Redis** on all nodes
2. **Configure clustering** in redis.conf
3. **Create cluster** using redis-cli
4. **Verify cluster** status and replication

```bash
# Create Redis cluster
redis-cli --cluster create \
  10.0.2.x:6379 10.0.3.x:6379 10.0.4.x:6379 \
  --cluster-replicas 0
```

## 🌐 Application Features

### Node.js Redis Client
- **Connection Management**: Handles Redis cluster connections
- **Error Handling**: Robust error handling and reconnection logic
- **Health Checks**: Built-in health monitoring
- **Docker Support**: Containerized deployment ready

### Key Functionalities
- Redis cluster connectivity
- Data operations (GET/SET/DEL)
- Connection pooling
- Performance monitoring

## 🔒 Security Features

- **Network Isolation**: Private subnets for Redis nodes
- **Access Control**: Bastion host for secure SSH access
- **Security Groups**: Restrictive firewall rules
- **Key Management**: Secure SSH key pair authentication
- **VPC Peering**: Secure cross-VPC communication

## 📊 Monitoring & Management

### Health Checks
- Infrastructure health via Terraform state
- Application health via Node.js health endpoints
- Redis cluster status monitoring

### Logging
- AWS CloudTrail for API logging
- Application logs via Docker/Node.js
- Jenkins pipeline execution logs

## 🧹 Cleanup & Maintenance

### Resource Cleanup
```bash
# Destroy infrastructure
terraform destroy

# Clean AWS resources
./cleanup-aws-resources.sh

# Quick cleanup
./quick-cleanup.sh
```

### Maintenance Tasks
- Regular security updates
- Redis cluster health monitoring
- Infrastructure cost optimization
- Backup and recovery procedures

## 🚦 Prerequisites

### Required Tools
- AWS CLI (configured)
- Terraform (>= 1.0)
- Ansible (>= 2.9)
- Node.js (>= 14)
- Docker
- Git

### AWS Requirements
- Valid AWS account with appropriate permissions
- Service limits: VPCs (1+), Elastic IPs (1+), EC2 instances (4+)

## 📈 Scalability & Performance

### Horizontal Scaling
- Add more Redis nodes to the cluster
- Distribute across additional availability zones
- Implement Redis Sentinel for high availability

### Performance Optimization
- Instance type optimization based on workload
- Redis configuration tuning
- Network performance optimization

## 🔄 CI/CD Pipeline

### Jenkins Pipeline Stages
1. **Checkout**: Pull latest code from repository
2. **Validate**: Terraform and Ansible validation
3. **Plan**: Generate Terraform execution plan
4. **Deploy**: Apply infrastructure changes
5. **Configure**: Run Ansible playbooks
6. **Test**: Verify deployment success
7. **Notify**: Send deployment status notifications

## 📞 Troubleshooting

### Common Issues
- **Service Limits**: Check AWS service quotas
- **Key Pair Errors**: Verify key pair exists and permissions
- **Network Connectivity**: Check security group rules
- **Redis Cluster**: Verify node connectivity and configuration

### Debug Commands
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify Terraform state
terraform show

# Test Ansible connectivity
ansible all -i aws_ec2.yaml -m ping
```

## 🎯 Use Cases

### Development Environment
- Local Redis cluster for development
- Testing Redis applications
- Learning Redis clustering concepts

### Production Deployment
- Scalable Redis infrastructure
- High-availability setup
- Enterprise-grade security

### DevOps Learning
- Infrastructure as Code practices
- CI/CD pipeline implementation
- Multi-tool integration (Terraform + Ansible + Jenkins)

## 📋 Next Steps

1. **Deploy Infrastructure**: Use deployment scripts
2. **Configure Redis Cluster**: Set up clustering
3. **Deploy Application**: Run Node.js Redis client
4. **Monitor Performance**: Set up monitoring dashboards
5. **Implement Backups**: Configure backup strategies
6. **Scale as Needed**: Add nodes or upgrade instances

---

**Project Status**: ✅ Production Ready  
**Last Updated**: June 2025  
**Maintainer**: Infrastructure Team
