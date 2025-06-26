#!/usr/bin/env python3
"""
Jenkins Pipeline Visualization for Redis Infrastructure Deployment
Creates a diagram showing the complete CI/CD pipeline flow
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.ci import Jenkins
from diagrams.onprem.vcs import Git
from diagrams.aws.compute import EC2
from diagrams.aws.network import VPC, NATGateway, InternetGateway
from diagrams.aws.security import IAM
from diagrams.onprem.iac import Terraform
from diagrams.programming.language import Python
from diagrams.onprem.monitoring import Grafana
from diagrams.aws.storage import S3
from diagrams.generic.blank import Blank
from diagrams.generic.device import Mobile
from diagrams.generic.storage import Storage
from diagrams.onprem.inmemory import Redis

# Configure diagram
graph_attr = {
    "fontsize": "16",
    "bgcolor": "white",
    "pad": "1.0",
    "splines": "ortho"
}

node_attr = {
    "fontsize": "12",
    "fontname": "Arial"
}

edge_attr = {
    "fontsize": "10",
    "fontname": "Arial"
}

with Diagram(
    "Redis Infrastructure Jenkins Pipeline",
    filename="jenkins_pipeline_diagram",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr
):
    
    # Source Control
    with Cluster("Source Control"):
        github = Git("GitHub Repository\n(SCM Polling)")
    
    # Jenkins Pipeline Stages
    with Cluster("Jenkins CI/CD Pipeline"):
        jenkins = Jenkins("Jenkins Master\n(SCM Trigger)")
        
        with Cluster("Pipeline Stages"):
            # Stage 1: Clone
            clone = Python("1. Clone Repository\n• Checkout SCM\n• Display commit info")
            
            # Stage 2: Pre-flight
            preflight = IAM("2. Pre-flight Checks\n• AWS credentials\n• Service limits\n• Existing resources")
            
            # Stage 3: Key Setup
            keysetup = Storage("3. Setup Key Pair\n• Create/validate key\n• Update configs\n• Set permissions")
            
            # Stage 4: Terraform Plan
            tfplan = Terraform("4. Terraform Plan\n• Initialize\n• Validate\n• Generate plan")
            
            # Stage 5: Terraform Apply
            tfapply = Terraform("5. Terraform Apply\n• Deploy infrastructure\n• Create resources\n• Output values")
            
            # Stage 6: Wait
            wait = Mobile("6. Wait for Infrastructure\n• Instance readiness\n• SSH availability\n• Service startup")
            
            # Stage 7: Ansible
            ansible = Redis("7. Ansible Configuration\n• Create inventory\n• Test connectivity\n• Deploy Redis")
            
            # Stage 8: Verification
            verify = Grafana("8. Post-Deployment\n• Verify instances\n• Check services\n• Generate reports")
            
            # Stage 9: Artifacts
            artifacts = S3("9. Generate Artifacts\n• Connection guide\n• Key files\n• Terraform outputs")
    
    # AWS Infrastructure
    with Cluster("AWS Infrastructure"):
        with Cluster("VPC (10.0.0.0/16)"):
            vpc = VPC("Custom VPC")
            igw = InternetGateway("Internet Gateway")
            nat = NATGateway("NAT Gateway")
            
            with Cluster("Public Subnet"):
                bastion = EC2("Bastion Host\n13.203.223.190")
            
            with Cluster("Private Subnets"):
                redis1 = EC2("Redis Node 1\n10.0.2.234")
                redis2 = EC2("Redis Node 2\n10.0.3.179") 
                redis3 = EC2("Redis Node 3\n10.0.4.119")
    
    # Deployment Artifacts
    with Cluster("Deployment Outputs"):
        connection_guide = Storage("Connection Guide")
        ssh_key = Storage("SSH Private Key")
        tf_outputs = Storage("Terraform Outputs")
    
    # Flow connections
    github >> Edge(label="SCM Polling\n(Every 5 min)", style="dashed") >> jenkins
    
    jenkins >> clone
    clone >> preflight
    preflight >> keysetup
    keysetup >> tfplan
    tfplan >> tfapply
    tfapply >> wait
    wait >> ansible
    ansible >> verify
    verify >> artifacts
    
    # Infrastructure deployment flow
    tfapply >> Edge(label="Deploy", color="blue") >> vpc
    vpc >> bastion
    vpc >> [redis1, redis2, redis3]
    
    # Ansible configuration flow
    ansible >> Edge(label="Configure via Bastion", color="green") >> bastion
    bastion >> Edge(label="SSH Proxy", color="green", style="dashed") >> [redis1, redis2, redis3]
    
    # Artifact generation
    artifacts >> [connection_guide, ssh_key, tf_outputs]
    
    # Network connections
    igw >> bastion
    nat >> [redis1, redis2, redis3]

print("✅ Jenkins Pipeline Diagram created successfully!")
print("📁 File saved as: jenkins_pipeline_diagram.png")
print("🔍 The diagram shows the complete CI/CD flow from SCM polling to Redis deployment")
