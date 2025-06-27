#!/usr/bin/env python3
"""
Redis Project Architecture Diagrams Generator (Working Version)
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
from diagrams.onprem.database import MongoDB  # Using MongoDB as Redis substitute
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
                 show=False,
                 graph_attr={"bgcolor": "white"}):
        
        # External Access
        users = Users("End Users")
        internet = InternetAlt1("Internet")
        
        with Cluster("AWS Cloud Region: ap-south-1"):
            
            with Cluster("Custom VPC (10.0.0.0/16)"):
                igw = InternetGateway("Internet\nGateway")
                
                with Cluster("Public Subnet (10.0.1.0/24)"):
                    bastion = EC2("Bastion Host\nt3.micro\nPublic IP")
                    nat_gw = NATGateway("NAT Gateway\nElastic IP")
                    public_sg = Firewall("Public Security Group\n• SSH (22): 0.0.0.0/0\n• HTTP (80): 0.0.0.0/0")
                
                with Cluster("Private Subnets - Multi-AZ"):
                    with Cluster("Availability Zone 1a\n(10.0.2.0/24)"):
                        redis1 = EC2("Redis Node 1\nt3.micro")
                        redis1_db = MongoDB("Redis Service\nPort: 6379")
                        
                    with Cluster("Availability Zone 1b\n(10.0.3.0/24)"):
                        redis2 = EC2("Redis Node 2\nt3.micro")
                        redis2_db = MongoDB("Redis Service\nPort: 6379")
                        
                    with Cluster("Availability Zone 1c\n(10.0.4.0/24)"):
                        redis3 = EC2("Redis Node 3\nt3.micro")
                        redis3_db = MongoDB("Redis Service\nPort: 6379")
                    
                    private_sg = Firewall("Private Security Group\n• Redis (6379): 0.0.0.0/0\n• Cluster (16379-16384)\n• SSH (22): VPC CIDR")
                
                # Persistent Storage
                ebs_storage = EBS("EBS Volumes\nData Persistence")
        
        # Network Flow
        users >> Edge(label="HTTPS/SSH Access") >> internet
        internet >> Edge(label="Public Traffic") >> igw
        igw >> Edge(label="Route to Public") >> bastion
        igw >> Edge(label="Route to NAT") >> nat_gw
        
        # SSH Jump Host Access
        bastion >> Edge(label="SSH Jump Host\n(Secure Access)", style="dashed", color="red") >> [redis1, redis2, redis3]
        
        # Internet Access for Private Instances
        nat_gw >> Edge(label="Internet Access\n(Updates/Packages)") >> [redis1, redis2, redis3]
        
        # Redis Cluster Communication
        redis1_db >> Edge(label="Cluster Sync", style="dotted", color="blue") >> redis2_db
        redis2_db >> Edge(label="Cluster Sync", style="dotted", color="blue") >> redis3_db
        redis3_db >> Edge(label="Cluster Sync", style="dotted", color="blue") >> redis1_db
        
        # Security Group Controls
        public_sg >> Edge(label="Controls Access") >> bastion
        private_sg >> Edge(label="Controls Access") >> [redis1, redis2, redis3]
        
        # Data Storage
        [redis1, redis2, redis3] >> Edge(label="Data Storage") >> ebs_storage

def create_cicd_pipeline_architecture():
    """Create CI/CD Pipeline Architecture Diagram"""
    
    with Diagram("CI/CD Pipeline Architecture", 
                 filename="cicd_pipeline_architecture", 
                 direction="LR",
                 show=False,
                 graph_attr={"bgcolor": "white"}):
        
        # Development Phase
        with Cluster("Development Environment"):
            developer = ClientUsers("Developer")
            local_git = Git("Local Git\nRepository")
            code_editor = Blank("Code Editor\n& Testing")
        
        # Source Control Management
        with Cluster("Source Control"):
            github = Github("GitHub Repository\nShivik0505/New_Redis")
            webhook = Blank("GitHub Webhook\nInstant Trigger")
            scm_polling = Blank("SCM Polling\nEvery 5 minutes")
        
        # CI/CD Orchestration
        with Cluster("Jenkins CI/CD Platform"):
            jenkins_server = Jenkins("Jenkins Server\nPipeline Orchestrator")
            
            with Cluster("Pipeline Execution Stages"):
                stage1 = Git("SCM Checkout\n& Validation")
                stage2 = Blank("Environment\nSetup & Checks")
                stage3 = Terraform("Infrastructure\nProvisioning")
                stage4 = Ansible("Configuration\nManagement")
                stage5 = Blank("Testing &\nVerification")
        
        # Infrastructure as Code Tools
        with Cluster("IaC & Automation Tools"):
            terraform_engine = Terraform("Terraform Engine\nInfrastructure Provisioning")
            ansible_engine = Ansible("Ansible Engine\nConfiguration Management")
            python_automation = Python("Python Scripts\nAutomation & Utilities")
        
        # Target AWS Infrastructure
        with Cluster("AWS Target Infrastructure"):
            vpc_networking = VPC("VPC & Networking\nSubnets, Routes, Gateways")
            compute_instances = EC2("EC2 Instances\n1 Bastion + 3 Redis Nodes")
            redis_cluster = MongoDB("Redis Cluster\nDistributed Database")
            security_groups = Firewall("Security Groups\nNetwork Access Control")
        
        # Monitoring & Artifacts
        with Cluster("Outputs & Monitoring"):
            build_artifacts = Storage("Build Artifacts\nSSH Keys, Reports, Logs")
            monitoring_dashboard = Grafana("Pipeline Monitoring\nBuild Status & Metrics")
            notifications = Blank("Notifications\nSlack, Email Alerts")
        
        # Development Flow
        developer >> Edge(label="Code Changes") >> code_editor
        code_editor >> Edge(label="Commit & Push") >> local_git
        local_git >> Edge(label="Push to Remote") >> github
        
        # Trigger Mechanisms
        github >> Edge(label="Instant Trigger") >> webhook
        github >> Edge(label="Scheduled Check") >> scm_polling
        [webhook, scm_polling] >> Edge(label="Trigger Build") >> jenkins_server
        
        # Pipeline Execution
        jenkins_server >> Edge(label="Execute Pipeline") >> stage1
        stage1 >> Edge(label="Next Stage") >> stage2
        stage2 >> Edge(label="Next Stage") >> stage3
        stage3 >> Edge(label="Next Stage") >> stage4
        stage4 >> Edge(label="Final Stage") >> stage5
        
        # Tool Integration
        stage3 >> Edge(label="Uses") >> terraform_engine
        stage4 >> Edge(label="Uses") >> ansible_engine
        jenkins_server >> Edge(label="Executes") >> python_automation
        
        # Infrastructure Provisioning
        terraform_engine >> Edge(label="Provisions") >> vpc_networking
        terraform_engine >> Edge(label="Creates") >> compute_instances
        terraform_engine >> Edge(label="Configures") >> security_groups
        ansible_engine >> Edge(label="Configures") >> redis_cluster
        
        # Output Generation
        jenkins_server >> Edge(label="Generates") >> build_artifacts
        jenkins_server >> Edge(label="Updates") >> monitoring_dashboard
        jenkins_server >> Edge(label="Sends") >> notifications

def create_detailed_pipeline_flow():
    """Create Detailed Pipeline Flow Diagram"""
    
    with Diagram("Detailed Jenkins Pipeline Flow", 
                 filename="detailed_pipeline_flow", 
                 direction="TB",
                 show=False,
                 graph_attr={"bgcolor": "white"}):
        
        # Pipeline Trigger Sources
        with Cluster("Pipeline Trigger Sources"):
            scm_polling = Blank("SCM Polling\nSchedule: H/5 * * * *\n(Every 5 minutes)")
            github_webhook = Github("GitHub Webhook\nInstant Notification\nPush Events")
            manual_trigger = ClientUsers("Manual Trigger\nDeveloper Initiated\nParameterized Build")
        
        # Jenkins Pipeline Execution Flow
        with Cluster("Jenkins Pipeline Execution"):
            
            # Stage 1: Source Code Management
            with Cluster("Stage 1: SCM Checkout & Validation"):
                git_checkout = Git("Git Repository\nCheckout & Clone")
                repo_validation = Blank("Repository Structure\nValidation & Checks")
                git_info_extract = Blank("Git Information\nExtraction & Logging")
                trigger_analysis = Blank("Build Trigger\nAnalysis & Detection")
            
            # Stage 2: Environment Preparation
            with Cluster("Stage 2: Environment Setup"):
                env_setup = Blank("Environment\nConfiguration & Setup")
                tool_validation = Blank("Tool Availability\nterraform, aws-cli, ansible")
                aws_credentials = Blank("AWS Credentials\nVerification & Testing")
                pre_flight_checks = Blank("Pre-flight Checks\nService Limits & Resources")
            
            # Stage 3: Infrastructure Management
            with Cluster("Stage 3: Infrastructure Operations"):
                key_pair_mgmt = Blank("AWS Key Pair\nManagement & Creation")
                terraform_init = Terraform("Terraform Initialize\nProvider & Backend Setup")
                terraform_plan = Terraform("Terraform Plan\nInfrastructure Planning")
                terraform_apply = Terraform("Terraform Apply/Destroy\nResource Provisioning")
            
            # Stage 4: Configuration & Deployment
            with Cluster("Stage 4: Configuration Management"):
                infra_verification = Blank("Infrastructure\nVerification & Health Check")
                ansible_inventory = Ansible("Ansible Inventory\nDynamic Host Discovery")
                ansible_playbook = Ansible("Ansible Playbook\nRedis Configuration")
                service_validation = Blank("Service Validation\n& Health Monitoring")
            
            # Stage 5: Reporting & Cleanup
            with Cluster("Stage 5: Reporting & Artifacts"):
                artifact_generation = Storage("Artifact Generation\nSSH Keys, Reports, Logs")
                build_reporting = Blank("Build Report\nCreation & Summary")
                notification_dispatch = Blank("Notification Dispatch\nStatus Updates & Alerts")
                workspace_cleanup = Blank("Workspace Cleanup\n& Resource Management")
        
        # AWS Resources Created/Managed
        with Cluster("AWS Resources Created"):
            vpc_resources = VPC("VPC Resources\nVPC, Subnets, Route Tables")
            compute_resources = EC2("Compute Resources\n4 EC2 Instances")
            network_resources = Blank("Network Resources\nIGW, NAT Gateway, EIPs")
            security_resources = Firewall("Security Resources\nSecurity Groups, NACLs")
            redis_services = MongoDB("Redis Services\nCluster Configuration")
        
        # Pipeline Outputs & Artifacts
        with Cluster("Pipeline Outputs"):
            ssh_key_file = Blank("SSH Key File\n(.pem for server access)")
            terraform_outputs = Blank("Terraform Outputs\n(JSON format)")
            build_summary = Blank("Build Summary\nReport & Metrics")
            connection_guide = Blank("Connection Guide\nAccess Instructions")
            monitoring_data = Blank("Monitoring Data\nPipeline Metrics")
        
        # Flow Connections - Trigger to Execution
        [scm_polling, github_webhook, manual_trigger] >> Edge(label="Initiates") >> git_checkout
        
        # Stage 1 Flow
        git_checkout >> repo_validation >> git_info_extract >> trigger_analysis
        trigger_analysis >> Edge(label="Proceed to Stage 2") >> env_setup
        
        # Stage 2 Flow
        env_setup >> tool_validation >> aws_credentials >> pre_flight_checks
        pre_flight_checks >> Edge(label="Proceed to Stage 3") >> key_pair_mgmt
        
        # Stage 3 Flow
        key_pair_mgmt >> terraform_init >> terraform_plan >> terraform_apply
        terraform_apply >> Edge(label="Proceed to Stage 4") >> infra_verification
        
        # Stage 4 Flow
        infra_verification >> ansible_inventory >> ansible_playbook >> service_validation
        service_validation >> Edge(label="Proceed to Stage 5") >> artifact_generation
        
        # Stage 5 Flow
        artifact_generation >> build_reporting >> notification_dispatch >> workspace_cleanup
        
        # Resource Creation Flow
        terraform_apply >> Edge(label="Creates") >> [vpc_resources, compute_resources, network_resources, security_resources]
        ansible_playbook >> Edge(label="Configures") >> redis_services
        
        # Output Generation Flow
        workspace_cleanup >> Edge(label="Generates") >> [ssh_key_file, terraform_outputs, build_summary, connection_guide, monitoring_data]

def create_network_topology():
    """Create Network Topology Diagram"""
    
    with Diagram("Network Topology & Security Architecture", 
                 filename="network_topology", 
                 direction="TB",
                 show=False,
                 graph_attr={"bgcolor": "white"}):
        
        # External Network
        internet = InternetAlt1("Internet\nPublic Network")
        
        with Cluster("AWS VPC (10.0.0.0/16) - Custom Network"):
            igw = InternetGateway("Internet Gateway\nPublic Internet Access")
            
            # Public Network Tier
            with Cluster("Public Network Tier"):
                public_route_table = Blank("Public Route Table\n0.0.0.0/0 → IGW")
                
                with Cluster("Public Subnet (10.0.1.0/24)"):
                    bastion_host = EC2("Bastion Host\nJump Server\n10.0.1.x")
                    nat_gateway = NATGateway("NAT Gateway\nOutbound Internet\n10.0.1.y")
                    
                    with Cluster("Public Security Group"):
                        public_sg_rules = Firewall("Security Rules:\n• SSH (22): 0.0.0.0/0\n• HTTP (80): 0.0.0.0/0\n• ICMP: All Sources")
            
            # Private Network Tier
            with Cluster("Private Network Tier"):
                private_route_table = Blank("Private Route Table\n0.0.0.0/0 → NAT Gateway")
                
                with Cluster("Multi-AZ Private Subnets"):
                    with Cluster("AZ-1a Subnet (10.0.2.0/24)"):
                        redis_node1 = EC2("Redis Node 1\nDatabase Server\n10.0.2.x")
                        redis_service1 = MongoDB("Redis Service\nPort: 6379\nCluster: 16379-16384")
                    
                    with Cluster("AZ-1b Subnet (10.0.3.0/24)"):
                        redis_node2 = EC2("Redis Node 2\nDatabase Server\n10.0.3.x")
                        redis_service2 = MongoDB("Redis Service\nPort: 6379\nCluster: 16379-16384")
                    
                    with Cluster("AZ-1c Subnet (10.0.4.0/24)"):
                        redis_node3 = EC2("Redis Node 3\nDatabase Server\n10.0.4.x")
                        redis_service3 = MongoDB("Redis Service\nPort: 6379\nCluster: 16379-16384")
                    
                    with Cluster("Private Security Group"):
                        private_sg_rules = Firewall("Security Rules:\n• Redis (6379): 0.0.0.0/0\n• Cluster (16379-16384): 0.0.0.0/0\n• SSH (22): VPC CIDR Only\n• ICMP: VPC CIDR Only")
        
        # Network Traffic Flow
        internet >> Edge(label="Public Internet Traffic") >> igw
        igw >> Edge(label="Route Public Traffic") >> public_route_table
        public_route_table >> Edge(label="Direct Access") >> bastion_host
        public_route_table >> Edge(label="NAT Traffic") >> nat_gateway
        
        # Secure SSH Access Pattern
        bastion_host >> Edge(label="SSH Jump Connection\n(Port 22 - Secure)", style="dashed", color="red") >> [redis_node1, redis_node2, redis_node3]
        
        # Outbound Internet Access
        nat_gateway >> Edge(label="Outbound Internet Access\n(Updates, Packages)") >> private_route_table
        private_route_table >> Edge(label="Route to Private Instances") >> [redis_node1, redis_node2, redis_node3]
        
        # Redis Service Hosting
        redis_node1 >> Edge(label="Hosts") >> redis_service1
        redis_node2 >> Edge(label="Hosts") >> redis_service2
        redis_node3 >> Edge(label="Hosts") >> redis_service3
        
        # Redis Cluster Inter-node Communication
        redis_service1 >> Edge(label="Cluster Synchronization", style="dotted", color="blue") >> redis_service2
        redis_service2 >> Edge(label="Cluster Synchronization", style="dotted", color="blue") >> redis_service3
        redis_service3 >> Edge(label="Cluster Synchronization", style="dotted", color="blue") >> redis_service1
        
        # Security Group Application
        public_sg_rules >> Edge(label="Applied to") >> bastion_host
        private_sg_rules >> Edge(label="Applied to") >> [redis_node1, redis_node2, redis_node3]

def create_project_overview():
    """Create Project Overview Diagram"""
    
    with Diagram("Redis Infrastructure Project - Complete Overview", 
                 filename="redis_project_overview", 
                 direction="TB",
                 show=False,
                 graph_attr={"bgcolor": "white"}):
        
        with Cluster("Redis Infrastructure Project Components"):
            
            # Source Code & Documentation Layer
            with Cluster("Source Code & Documentation"):
                github_repository = Github("GitHub Repository\nShivik0505/New_Redis\nVersion Control & Collaboration")
                terraform_iac = Terraform("Terraform Code\nInfrastructure as Code\nAWS Resource Definitions")
                ansible_config = Ansible("Ansible Playbooks\nConfiguration Management\nRedis Setup & Clustering")
                jenkins_pipeline = Jenkins("Jenkins Pipeline\nCI/CD Automation\nDeployment Orchestration")
                python_utilities = Python("Python Scripts\nAutomation Utilities\nDiagram Generation")
                documentation = Blank("Documentation Suite\nREADME, Guides, Diagrams\nTroubleshooting & Setup")
            
            # CI/CD Automation Layer
            with Cluster("CI/CD Automation Pipeline"):
                pipeline_orchestration = Jenkins("Pipeline Orchestration\nAutomated Deployment\nSCM Polling & Webhooks")
                trigger_mechanisms = Blank("Trigger Mechanisms\nSCM Polling (5min)\nGitHub Webhooks (Instant)\nManual Execution")
                automation_scripts = Python("Automation Scripts\nInfrastructure Validation\nHealth Checks & Reporting")
                artifact_management = Storage("Artifact Management\nBuild Reports, SSH Keys\nTerraform State, Logs")
            
            # Infrastructure Components Layer
            with Cluster("AWS Infrastructure Components"):
                network_infrastructure = VPC("Network Infrastructure\nCustom VPC (10.0.0.0/16)\nMulti-AZ Subnets")
                compute_infrastructure = EC2("Compute Infrastructure\nBastion Host (Public)\n3x Redis Nodes (Private)")
                security_infrastructure = Firewall("Security Infrastructure\nSecurity Groups & NACLs\nNetwork Access Control")
                storage_infrastructure = EBS("Storage Infrastructure\nEBS Volumes\nData Persistence")
                redis_cluster_service = MongoDB("Redis Cluster Service\n3-Node Cluster\nHigh Availability Setup")
            
            # Monitoring & Operations Layer
            with Cluster("Monitoring & Operations"):
                build_monitoring = Grafana("Build Monitoring\nPipeline Status\nDeployment Metrics")
                infrastructure_monitoring = Blank("Infrastructure Monitoring\nHealth Checks\nPerformance Metrics")
                logging_system = Blank("Logging System\nBuild Logs\nApplication Logs")
                alerting_system = Blank("Alerting System\nFailure Notifications\nStatus Updates")
            
            # Output & Access Layer
            with Cluster("Deployment Outputs & Access"):
                access_credentials = Blank("Access Credentials\nSSH Key Pairs\nConnection Information")
                connection_guides = Blank("Connection Guides\nServer Access Instructions\nRedis Client Configuration")
                architecture_diagrams = Blank("Architecture Diagrams\nInfrastructure Visualization\nNetwork Topology")
                deployment_reports = Storage("Deployment Reports\nBuild Summaries\nInfrastructure Status")
        
        # Project Component Relationships
        github_repository >> Edge(label="Contains") >> [terraform_iac, ansible_config, jenkins_pipeline, python_utilities, documentation]
        
        # CI/CD Flow
        trigger_mechanisms >> pipeline_orchestration >> automation_scripts
        pipeline_orchestration >> terraform_iac >> network_infrastructure
        pipeline_orchestration >> terraform_iac >> compute_infrastructure
        pipeline_orchestration >> terraform_iac >> security_infrastructure
        pipeline_orchestration >> terraform_iac >> storage_infrastructure
        pipeline_orchestration >> ansible_config >> redis_cluster_service
        
        # Monitoring Integration
        pipeline_orchestration >> [build_monitoring, infrastructure_monitoring, logging_system, alerting_system]
        
        # Output Generation
        pipeline_orchestration >> artifact_management >> [access_credentials, connection_guides, architecture_diagrams, deployment_reports]

def main():
    """Generate all architecture diagrams"""
    
    print("🎨 Creating Redis Project Architecture Diagrams with Python Diagrams...")
    print("=" * 70)
    
    try:
        print("1. Creating Infrastructure Architecture Diagram...")
        create_infrastructure_architecture()
        print("   ✅ redis_infrastructure_architecture.png created")
        
        print("2. Creating CI/CD Pipeline Architecture Diagram...")
        create_cicd_pipeline_architecture()
        print("   ✅ cicd_pipeline_architecture.png created")
        
        print("3. Creating Detailed Pipeline Flow Diagram...")
        create_detailed_pipeline_flow()
        print("   ✅ detailed_pipeline_flow.png created")
        
        print("4. Creating Network Topology Diagram...")
        create_network_topology()
        print("   ✅ network_topology.png created")
        
        print("5. Creating Project Overview Diagram...")
        create_project_overview()
        print("   ✅ redis_project_overview.png created")
        
        print("\n🎉 All architecture diagrams created successfully!")
        print("\n📁 Generated Diagram Files:")
        print("├── redis_infrastructure_architecture.png")
        print("├── cicd_pipeline_architecture.png") 
        print("├── detailed_pipeline_flow.png")
        print("├── network_topology.png")
        print("└── redis_project_overview.png")
        
        print("\n📋 Diagram Descriptions:")
        print("1. 🏗️  Infrastructure Architecture: AWS resources, VPC, and network layout")
        print("2. 🔄 CI/CD Pipeline Architecture: Jenkins automation and tool integration")
        print("3. 📊 Detailed Pipeline Flow: Step-by-step pipeline execution stages")
        print("4. 🌐 Network Topology: Security groups and network traffic flow")
        print("5. 📋 Project Overview: Complete project structure and components")
        
        print("\n🎯 Usage:")
        print("- Use these diagrams in presentations and documentation")
        print("- Include in technical reviews and architecture discussions")
        print("- Reference for team onboarding and training")
        print("- Add to project README and wiki pages")
        
    except Exception as e:
        print(f"❌ Error creating diagrams: {str(e)}")
        print("\n🔧 Troubleshooting:")
        print("1. Ensure 'diagrams' library is installed: pip install diagrams")
        print("2. Install Graphviz system dependency:")
        print("   - macOS: brew install graphviz")
        print("   - Ubuntu/Debian: sudo apt-get install graphviz")
        print("   - CentOS/RHEL: sudo yum install graphviz")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
