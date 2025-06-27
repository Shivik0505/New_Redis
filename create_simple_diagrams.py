#!/usr/bin/env python3
"""
Redis Project Architecture Diagrams Generator (Simplified)
Creates comprehensive architecture diagrams using Python diagrams library
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EC2
from diagrams.aws.network import VPC, InternetGateway, NATGateway
from diagrams.aws.storage import EBS
from diagrams.aws.general import Users, InternetAlt1
from diagrams.onprem.vcs import Git, Github
from diagrams.onprem.ci import Jenkins
from diagrams.onprem.iac import Terraform, Ansible
from diagrams.onprem.database import Redis
from diagrams.onprem.client import Users as ClientUsers
from diagrams.programming.language import Python
from diagrams.onprem.monitoring import Grafana
from diagrams.generic.blank import Blank
from diagrams.generic.network import Firewall
from diagrams.generic.storage import Storage

def create_infrastructure_architecture():
    """Create AWS Infrastructure Architecture Diagram"""
    
    with Diagram("Redis Infrastructure Architecture", 
                 filename="redis_infrastructure_architecture", 
                 direction="TB",
                 show=False):
        
        # External Users
        users = Users("End Users")
        internet = InternetAlt1("Internet")
        
        with Cluster("AWS Cloud (ap-south-1)"):
            
            with Cluster("Custom VPC (10.0.0.0/16)"):
                igw = InternetGateway("Internet Gateway")
                
                with Cluster("Public Subnet (10.0.1.0/24)"):
                    bastion = EC2("Bastion Host\n(t3.micro)")
                    nat_gw = NATGateway("NAT Gateway")
                    public_sg = Firewall("Public Security Group\nSSH:22, HTTP:80")
                
                with Cluster("Private Subnets"):
                    with Cluster("AZ-1a (10.0.2.0/24)"):
                        redis1 = EC2("Redis Node 1\n(t3.micro)")
                        redis1_db = Redis("Redis:6379")
                        
                    with Cluster("AZ-1b (10.0.3.0/24)"):
                        redis2 = EC2("Redis Node 2\n(t3.micro)")
                        redis2_db = Redis("Redis:6379")
                        
                    with Cluster("AZ-1c (10.0.4.0/24)"):
                        redis3 = EC2("Redis Node 3\n(t3.micro)")
                        redis3_db = Redis("Redis:6379")
                    
                    private_sg = Firewall("Private Security Group\nRedis:6379, Cluster:16379-16384")
                
                # Storage
                ebs_volumes = EBS("EBS Volumes")
        
        # Network Flow
        users >> Edge(label="Access") >> internet
        internet >> Edge(label="Route") >> igw
        igw >> Edge(label="Public") >> bastion
        bastion >> Edge(label="SSH Jump", style="dashed") >> [redis1, redis2, redis3]
        nat_gw >> Edge(label="Internet") >> [redis1, redis2, redis3]
        
        # Redis Cluster
        redis1_db >> Edge(label="Cluster", style="dotted") >> redis2_db
        redis2_db >> Edge(label="Cluster", style="dotted") >> redis3_db
        redis3_db >> Edge(label="Cluster", style="dotted") >> redis1_db
        
        # Security
        public_sg >> bastion
        private_sg >> [redis1, redis2, redis3]
        
        # Storage
        [redis1, redis2, redis3] >> ebs_volumes

def create_cicd_pipeline_architecture():
    """Create CI/CD Pipeline Architecture Diagram"""
    
    with Diagram("CI/CD Pipeline Architecture", 
                 filename="cicd_pipeline_architecture", 
                 direction="LR",
                 show=False):
        
        # Development
        with Cluster("Development"):
            developer = ClientUsers("Developer")
            git_local = Git("Local Git")
        
        # Source Control
        with Cluster("Source Control"):
            github = Github("GitHub Repository")
            webhook = Blank("Webhook")
        
        # CI/CD Pipeline
        with Cluster("Jenkins CI/CD"):
            jenkins = Jenkins("Jenkins Server")
            
            with Cluster("Pipeline Stages"):
                scm_stage = Git("SCM Checkout")
                terraform_stage = Terraform("Terraform")
                ansible_stage = Ansible("Ansible")
                test_stage = Blank("Testing")
        
        # Tools
        with Cluster("Infrastructure Tools"):
            terraform_tool = Terraform("Terraform Engine")
            ansible_tool = Ansible("Config Management")
            python_scripts = Python("Python Scripts")
        
        # Target Infrastructure
        with Cluster("AWS Infrastructure"):
            vpc_infra = VPC("VPC & Networking")
            ec2_infra = EC2("EC2 Instances")
            redis_cluster = Redis("Redis Cluster")
        
        # Monitoring
        with Cluster("Outputs"):
            artifacts = Storage("Build Artifacts")
            monitoring = Grafana("Monitoring")
        
        # Flow
        developer >> git_local >> github >> webhook >> jenkins
        jenkins >> scm_stage >> terraform_stage >> ansible_stage >> test_stage
        
        terraform_stage >> terraform_tool >> [vpc_infra, ec2_infra]
        ansible_stage >> ansible_tool >> redis_cluster
        jenkins >> python_scripts
        jenkins >> [artifacts, monitoring]

def create_detailed_pipeline_flow():
    """Create Detailed Pipeline Flow Diagram"""
    
    with Diagram("Detailed Jenkins Pipeline Flow", 
                 filename="detailed_pipeline_flow", 
                 direction="TB",
                 show=False):
        
        # Triggers
        with Cluster("Trigger Sources"):
            scm_polling = Blank("SCM Polling\n(Every 5 min)")
            github_webhook = Github("GitHub Webhook")
            manual_trigger = ClientUsers("Manual Trigger")
        
        # Pipeline Stages
        with Cluster("Jenkins Pipeline"):
            
            with Cluster("Stage 1: Checkout"):
                git_checkout = Git("Git Checkout")
                validation = Blank("Validation")
            
            with Cluster("Stage 2: Environment"):
                env_setup = Blank("Environment Setup")
                tool_check = Blank("Tool Verification")
                aws_check = Blank("AWS Credentials")
            
            with Cluster("Stage 3: Infrastructure"):
                key_mgmt = Blank("Key Management")
                tf_init = Terraform("Terraform Init")
                tf_plan = Terraform("Terraform Plan")
                tf_apply = Terraform("Terraform Apply")
            
            with Cluster("Stage 4: Configuration"):
                infra_verify = Blank("Infrastructure Verify")
                ansible_run = Ansible("Ansible Playbook")
                health_check = Blank("Health Checks")
            
            with Cluster("Stage 5: Reporting"):
                artifacts = Storage("Generate Artifacts")
                reports = Blank("Build Reports")
                notify = Blank("Notifications")
        
        # AWS Resources
        with Cluster("AWS Resources Created"):
            vpc_created = VPC("VPC & Subnets")
            instances_created = EC2("4 EC2 Instances")
            redis_deployed = Redis("Redis Cluster")
        
        # Outputs
        with Cluster("Pipeline Outputs"):
            ssh_key = Blank("SSH Key (.pem)")
            tf_outputs = Blank("Terraform Outputs")
            build_summary = Blank("Build Summary")
        
        # Connections
        [scm_polling, github_webhook, manual_trigger] >> git_checkout
        git_checkout >> validation >> env_setup >> tool_check >> aws_check
        aws_check >> key_mgmt >> tf_init >> tf_plan >> tf_apply
        tf_apply >> infra_verify >> ansible_run >> health_check
        health_check >> artifacts >> reports >> notify
        
        # Resource creation
        tf_apply >> [vpc_created, instances_created]
        ansible_run >> redis_deployed
        notify >> [ssh_key, tf_outputs, build_summary]

def create_network_topology():
    """Create Network Topology Diagram"""
    
    with Diagram("Network Topology & Security", 
                 filename="network_topology", 
                 direction="TB",
                 show=False):
        
        internet = InternetAlt1("Internet")
        
        with Cluster("AWS VPC (10.0.0.0/16)"):
            igw = InternetGateway("Internet Gateway")
            
            with Cluster("Public Subnet (10.0.1.0/24)"):
                public_rt = Blank("Public Route Table")
                bastion = EC2("Bastion Host")
                nat_gw = NATGateway("NAT Gateway")
                public_sg = Firewall("Public SG\nSSH:22, HTTP:80")
            
            with Cluster("Private Subnets"):
                private_rt = Blank("Private Route Table")
                
                redis_node1 = EC2("Redis Node 1\n(10.0.2.x)")
                redis_node2 = EC2("Redis Node 2\n(10.0.3.x)")
                redis_node3 = EC2("Redis Node 3\n(10.0.4.x)")
                
                redis_svc1 = Redis("Redis:6379")
                redis_svc2 = Redis("Redis:6379")
                redis_svc3 = Redis("Redis:6379")
                
                private_sg = Firewall("Private SG\nRedis:6379\nCluster:16379-16384")
        
        # Network Flow
        internet >> igw >> public_rt >> [bastion, nat_gw]
        bastion >> Edge(label="SSH Jump", style="dashed") >> [redis_node1, redis_node2, redis_node3]
        nat_gw >> private_rt >> [redis_node1, redis_node2, redis_node3]
        
        # Redis Services
        redis_node1 >> redis_svc1
        redis_node2 >> redis_svc2
        redis_node3 >> redis_svc3
        
        # Cluster Communication
        redis_svc1 >> Edge(style="dotted") >> redis_svc2
        redis_svc2 >> Edge(style="dotted") >> redis_svc3
        redis_svc3 >> Edge(style="dotted") >> redis_svc1
        
        # Security Groups
        public_sg >> bastion
        private_sg >> [redis_node1, redis_node2, redis_node3]

def create_project_overview():
    """Create Project Overview Diagram"""
    
    with Diagram("Redis Project Overview", 
                 filename="redis_project_overview", 
                 direction="TB",
                 show=False):
        
        with Cluster("Redis Infrastructure Project"):
            
            with Cluster("Source Code & Documentation"):
                github_repo = Github("GitHub Repository\nShivik0505/New_Redis")
                terraform_code = Terraform("Terraform IaC")
                ansible_code = Ansible("Ansible Config")
                jenkins_code = Jenkins("Jenkins Pipeline")
                docs = Blank("Documentation\n& Guides")
            
            with Cluster("CI/CD Pipeline"):
                pipeline = Jenkins("Jenkins Pipeline")
                scm_trigger = Blank("SCM Polling\n& Webhooks")
                automation = Python("Python Scripts")
            
            with Cluster("Infrastructure Components"):
                aws_vpc = VPC("AWS VPC")
                bastion_host = EC2("Bastion Host")
                redis_nodes = Redis("Redis Cluster\n(3 Nodes)")
                security = Firewall("Security Groups")
            
            with Cluster("Outputs & Artifacts"):
                ssh_keys = Blank("SSH Keys")
                build_reports = Storage("Build Reports")
                connection_guides = Blank("Connection Guides")
                diagrams = Blank("Architecture Diagrams")
        
        # Relationships
        github_repo >> [terraform_code, ansible_code, jenkins_code, docs]
        scm_trigger >> pipeline >> automation
        pipeline >> terraform_code >> [aws_vpc, bastion_host, security]
        pipeline >> ansible_code >> redis_nodes
        pipeline >> [ssh_keys, build_reports, connection_guides, diagrams]

def main():
    """Generate all architecture diagrams"""
    
    print("🎨 Creating Redis Project Architecture Diagrams...")
    print("=" * 50)
    
    try:
        print("1. Creating Infrastructure Architecture...")
        create_infrastructure_architecture()
        print("   ✅ redis_infrastructure_architecture.png")
        
        print("2. Creating CI/CD Pipeline Architecture...")
        create_cicd_pipeline_architecture()
        print("   ✅ cicd_pipeline_architecture.png")
        
        print("3. Creating Detailed Pipeline Flow...")
        create_detailed_pipeline_flow()
        print("   ✅ detailed_pipeline_flow.png")
        
        print("4. Creating Network Topology...")
        create_network_topology()
        print("   ✅ network_topology.png")
        
        print("5. Creating Project Overview...")
        create_project_overview()
        print("   ✅ redis_project_overview.png")
        
        print("\n🎉 All diagrams created successfully!")
        print("\n📁 Generated Files:")
        print("- redis_infrastructure_architecture.png")
        print("- cicd_pipeline_architecture.png") 
        print("- detailed_pipeline_flow.png")
        print("- network_topology.png")
        print("- redis_project_overview.png")
        
        print("\n📋 Diagram Descriptions:")
        print("1. Infrastructure: AWS resources and network layout")
        print("2. CI/CD Pipeline: Jenkins automation workflow")
        print("3. Pipeline Flow: Detailed step-by-step execution")
        print("4. Network Topology: Security and network configuration")
        print("5. Project Overview: Complete project structure")
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
