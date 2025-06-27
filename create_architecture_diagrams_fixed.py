#!/usr/bin/env python3
"""
Redis Project Architecture Diagrams Generator
Creates comprehensive architecture diagrams using Python diagrams library
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EC2
from diagrams.aws.network import VPC, PublicSubnet, PrivateSubnet, InternetGateway, NATGateway
from diagrams.aws.security import IAM
from diagrams.aws.storage import EBS
from diagrams.aws.general import Users, Internet
from diagrams.onprem.vcs import Git, Github
from diagrams.onprem.ci import Jenkins
from diagrams.onprem.iac import Terraform, Ansible
from diagrams.onprem.database import Redis
from diagrams.onprem.client import Users as ClientUsers
from diagrams.programming.language import Python, Nodejs
from diagrams.onprem.monitoring import Grafana
from diagrams.generic.blank import Blank
from diagrams.generic.network import Firewall
from diagrams.generic.storage import Storage
import os

def create_infrastructure_architecture():
    """Create AWS Infrastructure Architecture Diagram"""
    
    with Diagram("Redis Infrastructure Architecture", 
                 filename="redis_infrastructure_architecture", 
                 direction="TB",
                 show=False,
                 graph_attr={
                     "fontsize": "20",
                     "bgcolor": "white",
                     "pad": "1.0",
                     "splines": "ortho"
                 }):
        
        # External Users
        users = Users("End Users")
        internet = Internet("Internet")
        
        with Cluster("AWS Cloud (ap-south-1)"):
            
            with Cluster("Custom VPC (10.0.0.0/16)"):
                igw = InternetGateway("Internet Gateway")
                
                with Cluster("Public Subnet (10.0.1.0/24)"):
                    bastion = EC2("Bastion Host\n(t3.micro)")
                    nat_gw = NATGateway("NAT Gateway")
                    public_sg = Firewall("Public SG\nSSH:22, HTTP:80")
                
                with Cluster("Private Subnets"):
                    with Cluster("AZ-1a (10.0.2.0/24)"):
                        redis1 = EC2("Redis Node 1\n(t3.micro)")
                        redis1_db = Redis("Redis Instance\nPort: 6379")
                        
                    with Cluster("AZ-1b (10.0.3.0/24)"):
                        redis2 = EC2("Redis Node 2\n(t3.micro)")
                        redis2_db = Redis("Redis Instance\nPort: 6379")
                        
                    with Cluster("AZ-1c (10.0.4.0/24)"):
                        redis3 = EC2("Redis Node 3\n(t3.micro)")
                        redis3_db = Redis("Redis Instance\nPort: 6379")
                    
                    private_sg = Firewall("Private SG\nRedis:6379\nCluster:16379-16384")
                
                # Storage
                ebs_volumes = EBS("EBS Volumes\nFor Data Persistence")
        
        # Network Flow
        users >> Edge(label="HTTPS/SSH") >> internet
        internet >> Edge(label="Public Access") >> igw
        igw >> Edge(label="Route Traffic") >> bastion
        bastion >> Edge(label="SSH Jump", style="dashed") >> [redis1, redis2, redis3]
        nat_gw >> Edge(label="Internet Access") >> [redis1, redis2, redis3]
        
        # Redis Cluster
        redis1_db >> Edge(label="Cluster\nCommunication", style="dotted") >> redis2_db
        redis2_db >> Edge(label="Cluster\nCommunication", style="dotted") >> redis3_db
        redis3_db >> Edge(label="Cluster\nCommunication", style="dotted") >> redis1_db
        
        # Security Groups
        public_sg >> Edge(label="Controls") >> bastion
        private_sg >> Edge(label="Controls") >> [redis1, redis2, redis3]
        
        # Storage
        [redis1, redis2, redis3] >> Edge(label="Data Storage") >> ebs_volumes

def create_cicd_pipeline_architecture():
    """Create CI/CD Pipeline Architecture Diagram"""
    
    with Diagram("CI/CD Pipeline Architecture", 
                 filename="cicd_pipeline_architecture", 
                 direction="LR",
                 show=False,
                 graph_attr={
                     "fontsize": "20",
                     "bgcolor": "white",
                     "pad": "1.0",
                     "splines": "ortho"
                 }):
        
        # Development Phase
        with Cluster("Development"):
            developer = ClientUsers("Developer")
            git_local = Git("Local Git")
        
        # Source Control
        with Cluster("Source Control"):
            github = Github("GitHub Repository\nShivik0505/New_Redis")
            webhook = Blank("Webhook\nTrigger")
        
        # CI/CD Pipeline
        with Cluster("Jenkins CI/CD"):
            jenkins = Jenkins("Jenkins Server")
            
            with Cluster("Pipeline Stages"):
                scm_checkout = Blank("SCM Checkout\n& Validation")
                terraform_stage = Terraform("Terraform\nPlan & Apply")
                ansible_stage = Ansible("Ansible\nConfiguration")
                testing_stage = Blank("Infrastructure\nTesting")
        
        # Infrastructure as Code
        with Cluster("Infrastructure Tools"):
            terraform_tool = Terraform("Terraform\nIaC Engine")
            ansible_tool = Ansible("Ansible\nConfig Mgmt")
            python_scripts = Python("Python\nAutomation Scripts")
        
        # Target Infrastructure
        with Cluster("AWS Infrastructure"):
            vpc_infra = VPC("VPC & Networking")
            ec2_infra = EC2("EC2 Instances")
            redis_cluster = Redis("Redis Cluster")
        
        # Monitoring & Reporting
        with Cluster("Monitoring"):
            artifacts = Storage("Build Artifacts\n& Reports")
            monitoring = Grafana("Pipeline\nMonitoring")
        
        # Flow
        developer >> Edge(label="Code Changes") >> git_local
        git_local >> Edge(label="Push") >> github
        github >> Edge(label="Webhook/Polling") >> webhook
        webhook >> Edge(label="Trigger") >> jenkins
        
        jenkins >> Edge(label="Execute") >> scm_checkout
        scm_checkout >> Edge(label="Next") >> terraform_stage
        terraform_stage >> Edge(label="Next") >> ansible_stage
        ansible_stage >> Edge(label="Next") >> testing_stage
        
        terraform_stage >> Edge(label="Uses") >> terraform_tool
        ansible_stage >> Edge(label="Uses") >> ansible_tool
        jenkins >> Edge(label="Scripts") >> python_scripts
        
        terraform_tool >> Edge(label="Provisions") >> vpc_infra
        terraform_tool >> Edge(label="Creates") >> ec2_infra
        ansible_tool >> Edge(label="Configures") >> redis_cluster
        
        jenkins >> Edge(label="Generates") >> artifacts
        jenkins >> Edge(label="Reports") >> monitoring

def create_detailed_pipeline_flow():
    """Create Detailed Pipeline Flow Diagram"""
    
    with Diagram("Detailed Jenkins Pipeline Flow", 
                 filename="detailed_pipeline_flow", 
                 direction="TB",
                 show=False,
                 graph_attr={
                     "fontsize": "18",
                     "bgcolor": "white",
                     "pad": "1.0",
                     "splines": "ortho"
                 }):
        
        # Trigger Sources
        with Cluster("Trigger Sources"):
            scm_polling = Blank("SCM Polling\n(H/5 * * * *)")
            github_webhook = Github("GitHub Webhook\n(Instant)")
            manual_trigger = ClientUsers("Manual Trigger")
        
        # Jenkins Pipeline Stages
        with Cluster("Jenkins Pipeline Execution"):
            
            # Stage 1: SCM & Validation
            with Cluster("Stage 1: SCM Checkout"):
                git_checkout = Git("Git Checkout\n& Validation")
                repo_validation = Blank("Repository\nStructure Check")
                git_info = Blank("Extract Git\nInformation")
            
            # Stage 2: Environment Setup
            with Cluster("Stage 2: Environment"):
                env_setup = Blank("Environment\nSetup")
                tool_validation = Blank("Tool Validation\n(terraform, aws, ansible)")
                aws_creds = Blank("AWS Credentials\nVerification")
            
            # Stage 3: Infrastructure
            with Cluster("Stage 3: Infrastructure"):
                key_mgmt = Blank("Key Pair\nManagement")
                tf_init = Terraform("Terraform\nInit & Validate")
                tf_plan = Terraform("Terraform\nPlan")
                tf_apply = Terraform("Terraform\nApply/Destroy")
            
            # Stage 4: Configuration
            with Cluster("Stage 4: Configuration"):
                infra_verify = Blank("Infrastructure\nVerification")
                ansible_config = Ansible("Ansible\nPlaybook Execution")
                health_check = Blank("Health Checks\n& Testing")
            
            # Stage 5: Reporting
            with Cluster("Stage 5: Reporting"):
                artifact_gen = Storage("Artifact\nGeneration")
                build_report = Blank("Build Report\nCreation")
                notification = Blank("Notifications\n& Alerts")
        
        # AWS Resources Created
        with Cluster("AWS Resources Created"):
            vpc_created = VPC("VPC & Subnets")
            ec2_created = EC2("4 EC2 Instances")
            sg_created = Firewall("Security Groups")
            redis_deployed = Redis("Redis Cluster")
        
        # Artifacts & Outputs
        with Cluster("Pipeline Outputs"):
            ssh_key = Blank("SSH Key\n(.pem file)")
            tf_outputs = Blank("Terraform\nOutputs (JSON)")
            build_summary = Blank("Build Summary\nReport")
            connection_guide = Blank("Connection\nGuide")
        
        # Flow connections
        [scm_polling, github_webhook, manual_trigger] >> Edge(label="Triggers") >> git_checkout
        
        git_checkout >> repo_validation >> git_info
        git_info >> Edge(label="Next Stage") >> env_setup
        
        env_setup >> tool_validation >> aws_creds
        aws_creds >> Edge(label="Next Stage") >> key_mgmt
        
        key_mgmt >> tf_init >> tf_plan >> tf_apply
        tf_apply >> Edge(label="Next Stage") >> infra_verify
        
        infra_verify >> ansible_config >> health_check
        health_check >> Edge(label="Final Stage") >> artifact_gen
        
        artifact_gen >> build_report >> notification
        
        # Resource creation
        tf_apply >> Edge(label="Creates") >> [vpc_created, ec2_created, sg_created]
        ansible_config >> Edge(label="Configures") >> redis_deployed
        
        # Output generation
        notification >> Edge(label="Generates") >> [ssh_key, tf_outputs, build_summary, connection_guide]

def create_network_topology():
    """Create Network Topology Diagram"""
    
    with Diagram("Network Topology & Security", 
                 filename="network_topology", 
                 direction="TB",
                 show=False,
                 graph_attr={
                     "fontsize": "18",
                     "bgcolor": "white",
                     "pad": "1.0",
                     "splines": "ortho"
                 }):
        
        # External Network
        internet = Internet("Internet")
        
        with Cluster("AWS VPC (10.0.0.0/16)"):
            igw = InternetGateway("Internet Gateway")
            
            # Public Network
            with Cluster("Public Network (10.0.1.0/24)"):
                public_rt = Blank("Public Route Table")
                bastion_host = EC2("Bastion Host\n10.0.1.x")
                nat_gateway = NATGateway("NAT Gateway\n10.0.1.y")
                
                with Cluster("Public Security Group"):
                    pub_sg_rules = Firewall("Rules:\nSSH (22) - 0.0.0.0/0\nHTTP (80) - 0.0.0.0/0\nICMP - All")
            
            # Private Networks
            with Cluster("Private Networks"):
                private_rt = Blank("Private Route Table")
                
                with Cluster("Redis Node 1 (AZ-1a)"):
                    redis_node1 = EC2("Redis Node 1\n10.0.2.x")
                    redis_svc1 = Redis("Redis:6379\nCluster:16379-16384")
                
                with Cluster("Redis Node 2 (AZ-1b)"):
                    redis_node2 = EC2("Redis Node 2\n10.0.3.x")
                    redis_svc2 = Redis("Redis:6379\nCluster:16379-16384")
                
                with Cluster("Redis Node 3 (AZ-1c)"):
                    redis_node3 = EC2("Redis Node 3\n10.0.4.x")
                    redis_svc3 = Redis("Redis:6379\nCluster:16379-16384")
                
                with Cluster("Private Security Group"):
                    priv_sg_rules = Firewall("Rules:\nRedis (6379) - 0.0.0.0/0\nCluster (16379-16384) - 0.0.0.0/0\nSSH (22) - VPC CIDR\nICMP - VPC CIDR")
        
        # Network Flow
        internet >> Edge(label="Public Traffic") >> igw
        igw >> Edge(label="Route") >> public_rt
        public_rt >> Edge(label="Direct") >> bastion_host
        public_rt >> Edge(label="Direct") >> nat_gateway
        
        bastion_host >> Edge(label="SSH Jump\n(Port 22)", style="dashed", color="red") >> [redis_node1, redis_node2, redis_node3]
        
        nat_gateway >> Edge(label="Internet Access") >> private_rt
        private_rt >> Edge(label="Route") >> [redis_node1, redis_node2, redis_node3]
        
        # Redis Cluster Communication
        redis_svc1 >> Edge(label="Cluster Sync", style="dotted", color="blue") >> redis_svc2
        redis_svc2 >> Edge(label="Cluster Sync", style="dotted", color="blue") >> redis_svc3
        redis_svc3 >> Edge(label="Cluster Sync", style="dotted", color="blue") >> redis_svc1
        
        # Security Group Application
        pub_sg_rules >> Edge(label="Applied to") >> bastion_host
        priv_sg_rules >> Edge(label="Applied to") >> [redis_node1, redis_node2, redis_node3]

def create_deployment_workflow():
    """Create Deployment Workflow Diagram"""
    
    with Diagram("Deployment Workflow", 
                 filename="deployment_workflow", 
                 direction="LR",
                 show=False,
                 graph_attr={
                     "fontsize": "18",
                     "bgcolor": "white",
                     "pad": "1.0",
                     "splines": "ortho"
                 }):
        
        # Development Workflow
        with Cluster("Development Workflow"):
            dev_local = ClientUsers("Developer")
            code_changes = Blank("Code Changes\n& Testing")
            git_commit = Git("Git Commit\n& Push")
        
        # CI/CD Automation
        with Cluster("Automated CI/CD"):
            trigger_detection = Blank("Trigger Detection\n(SCM/Webhook)")
            pipeline_start = Jenkins("Pipeline\nExecution Start")
            
            # Parallel Execution
            with Cluster("Parallel Execution"):
                infra_branch = Terraform("Infrastructure\nBranch")
                config_branch = Ansible("Configuration\nBranch")
        
        # Infrastructure Provisioning
        with Cluster("Infrastructure Provisioning"):
            aws_resources = Blank("AWS Resource\nCreation")
            network_setup = VPC("Network\nConfiguration")
            instance_launch = EC2("Instance\nLaunching")
        
        # Application Configuration
        with Cluster("Application Configuration"):
            redis_install = Redis("Redis\nInstallation")
            cluster_config = Blank("Cluster\nConfiguration")
            service_start = Blank("Service\nStartup")
        
        # Verification & Deployment
        with Cluster("Verification"):
            health_checks = Blank("Health\nChecks")
            connectivity_test = Blank("Connectivity\nTesting")
            deployment_complete = Blank("Deployment\nComplete")
        
        # Outputs
        with Cluster("Deployment Outputs"):
            access_keys = Blank("SSH Keys\n& Credentials")
            connection_info = Blank("Connection\nInformation")
            monitoring_setup = Grafana("Monitoring\n& Alerts")
        
        # Workflow
        dev_local >> code_changes >> git_commit
        git_commit >> Edge(label="Triggers") >> trigger_detection
        trigger_detection >> pipeline_start
        
        pipeline_start >> Edge(label="Parallel") >> [infra_branch, config_branch]
        
        infra_branch >> aws_resources >> network_setup >> instance_launch
        config_branch >> redis_install >> cluster_config >> service_start
        
        [instance_launch, service_start] >> Edge(label="Verify") >> health_checks
        health_checks >> connectivity_test >> deployment_complete
        
        deployment_complete >> Edge(label="Generates") >> [access_keys, connection_info, monitoring_setup]

def create_project_overview():
    """Create Project Overview Diagram"""
    
    with Diagram("Redis Project Overview", 
                 filename="redis_project_overview", 
                 direction="TB",
                 show=False,
                 graph_attr={
                     "fontsize": "20",
                     "bgcolor": "white",
                     "pad": "1.0",
                     "splines": "ortho"
                 }):
        
        # Project Components
        with Cluster("Redis Infrastructure Project"):
            
            # Source Code Management
            with Cluster("Source Code"):
                github_repo = Github("GitHub Repository\nShivik0505/New_Redis")
                terraform_code = Terraform("Terraform\nInfrastructure Code")
                ansible_code = Ansible("Ansible\nConfiguration")
                jenkins_pipeline = Jenkins("Jenkins\nPipeline Code")
                python_tools = Python("Python\nAutomation Tools")
            
            # Documentation
            with Cluster("Documentation"):
                readme = Blank("README.md\nProject Guide")
                doc_md = Blank("DOC.md\nTechnical Docs")
                diagrams_doc = Blank("DIAGRAMS.md\nVisual Docs")
                setup_guides = Blank("Setup Guides\n& Troubleshooting")
            
            # Infrastructure Diagrams
            with Cluster("Architecture Diagrams"):
                infra_diagram = Blank("Infrastructure\nArchitecture")
                pipeline_diagram = Blank("CI/CD Pipeline\nFlow")
                network_diagram = Blank("Network\nTopology")
                deployment_diagram = Blank("Deployment\nWorkflow")
            
            # Deployment Artifacts
            with Cluster("Deployment Artifacts"):
                ssh_keys = Blank("SSH Keys\n& Credentials")
                tf_state = Blank("Terraform\nState Files")
                build_reports = Blank("Build Reports\n& Logs")
                connection_guides = Blank("Connection\nGuides")
        
        # Target Infrastructure
        with Cluster("Deployed Infrastructure"):
            aws_vpc = VPC("AWS VPC\n(ap-south-1)")
            bastion_server = EC2("Bastion Host\n(Public)")
            redis_cluster_nodes = [
                Redis("Redis Node 1\n(Private)"),
                Redis("Redis Node 2\n(Private)"),
                Redis("Redis Node 3\n(Private)")
            ]
        
        # Relationships
        github_repo >> Edge(label="Contains") >> [terraform_code, ansible_code, jenkins_pipeline, python_tools]
        github_repo >> Edge(label="Includes") >> [readme, doc_md, diagrams_doc, setup_guides]
        github_repo >> Edge(label="Generates") >> [infra_diagram, pipeline_diagram, network_diagram, deployment_diagram]
        
        jenkins_pipeline >> Edge(label="Executes") >> terraform_code
        jenkins_pipeline >> Edge(label="Runs") >> ansible_code
        jenkins_pipeline >> Edge(label="Creates") >> [ssh_keys, tf_state, build_reports, connection_guides]
        
        terraform_code >> Edge(label="Provisions") >> aws_vpc
        terraform_code >> Edge(label="Creates") >> bastion_server
        terraform_code >> Edge(label="Launches") >> redis_cluster_nodes
        
        ansible_code >> Edge(label="Configures") >> redis_cluster_nodes

def main():
    """Generate all architecture diagrams"""
    
    print("🎨 Creating Redis Project Architecture Diagrams...")
    print("=" * 50)
    
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
        
        print("5. Creating Deployment Workflow Diagram...")
        create_deployment_workflow()
        print("   ✅ deployment_workflow.png created")
        
        print("6. Creating Project Overview Diagram...")
        create_project_overview()
        print("   ✅ redis_project_overview.png created")
        
        print("\n🎉 All architecture diagrams created successfully!")
        print("\nGenerated Files:")
        print("- redis_infrastructure_architecture.png")
        print("- cicd_pipeline_architecture.png") 
        print("- detailed_pipeline_flow.png")
        print("- network_topology.png")
        print("- deployment_workflow.png")
        print("- redis_project_overview.png")
        
        print("\n📋 Diagram Descriptions:")
        print("1. Infrastructure Architecture: AWS resources and network topology")
        print("2. CI/CD Pipeline Architecture: Jenkins pipeline and tool integration")
        print("3. Detailed Pipeline Flow: Step-by-step pipeline execution")
        print("4. Network Topology: Security groups and network flow")
        print("5. Deployment Workflow: End-to-end deployment process")
        print("6. Project Overview: Complete project structure and components")
        
    except Exception as e:
        print(f"❌ Error creating diagrams: {str(e)}")
        print("Make sure you have the 'diagrams' library installed:")
        print("pip install diagrams")
        print("And Graphviz system dependency:")
        print("brew install graphviz  # macOS")
        print("sudo apt-get install graphviz  # Ubuntu/Debian")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
