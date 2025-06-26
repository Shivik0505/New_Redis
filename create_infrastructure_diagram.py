#!/usr/bin/env python3
"""
Redis Infrastructure Architecture Diagram
Shows the AWS infrastructure deployed by the Jenkins pipeline
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EC2
from diagrams.aws.network import VPC, NATGateway, InternetGateway
from diagrams.aws.security import IAM
from diagrams.onprem.inmemory import Redis
from diagrams.onprem.client import User
from diagrams.aws.general import General

# Configure diagram
graph_attr = {
    "fontsize": "14",
    "bgcolor": "white",
    "pad": "1.0",
    "splines": "ortho"
}

with Diagram(
    "Redis Infrastructure Architecture",
    filename="redis_infrastructure_architecture",
    show=False,
    direction="TB",
    graph_attr=graph_attr
):
    
    # External Access
    user = User("Developer/Admin")
    internet = InternetGateway("Internet Gateway")
    
    # VPC
    with Cluster("VPC: redis-VPC (10.0.0.0/16)"):
        vpc = VPC("Custom VPC")
        
        # Public Subnet
        with Cluster("Public Subnet (10.0.1.0/24)"):
            with Cluster("Availability Zone: ap-south-1a"):
                bastion = EC2("Bastion Host\nredis-public\n13.203.223.190\nt3.micro")
                eip = General("Elastic IP")
        
        # NAT Gateway
        nat_gateway = NATGateway("NAT Gateway")
        
        # Private Subnets
        with Cluster("Private Subnets"):
            with Cluster("AZ: ap-south-1a (10.0.2.0/24)"):
                redis1 = EC2("Redis Node 1\nredis-private-1\n10.0.2.234\nt3.micro")
                redis1_service = Redis("Redis Server\nPort: 6379\nCluster: Enabled")
            
            with Cluster("AZ: ap-south-1b (10.0.3.0/24)"):
                redis2 = EC2("Redis Node 2\nredis-private-2\n10.0.3.179\nt3.micro")
                redis2_service = Redis("Redis Server\nPort: 6379\nCluster: Enabled")
            
            with Cluster("AZ: ap-south-1c (10.0.4.0/24)"):
                redis3 = EC2("Redis Node 3\nredis-private-3\n10.0.4.119\nt3.micro")
                redis3_service = Redis("Redis Server\nPort: 6379\nCluster: Enabled")
    
    # Security Groups
    with Cluster("Security Groups"):
        public_sg = IAM("Public SG\n• SSH (22): 0.0.0.0/0\n• HTTP (80): 0.0.0.0/0\n• ICMP: All")
        private_sg = IAM("Private SG\n• Redis (6379): 0.0.0.0/0\n• Redis Cluster (16379-16384)\n• SSH (22): VPC CIDR")
    
    # Route Tables
    with Cluster("Route Tables"):
        public_rt = General("Public Route Table\n• 0.0.0.0/0 → IGW\n• 10.0.0.0/16 → Local")
        private_rt = General("Private Route Table\n• 0.0.0.0/0 → NAT\n• 10.0.0.0/16 → Local")
    
    # Network Flow
    user >> Edge(label="SSH Access", color="blue") >> internet
    internet >> Edge(label="Public Traffic", color="blue") >> bastion
    bastion >> Edge(label="SSH Proxy", color="green", style="dashed") >> [redis1, redis2, redis3]
    
    # Internet Access for Private Instances
    [redis1, redis2, redis3] >> Edge(label="Outbound Traffic", color="orange") >> nat_gateway
    nat_gateway >> Edge(label="Internet Access", color="orange") >> internet
    
    # Redis Services
    redis1 >> redis1_service
    redis2 >> redis2_service
    redis3 >> redis3_service
    
    # Redis Cluster Communication
    redis1_service >> Edge(label="Cluster Communication", color="red", style="dotted") >> redis2_service
    redis2_service >> Edge(label="Cluster Communication", color="red", style="dotted") >> redis3_service
    redis3_service >> Edge(label="Cluster Communication", color="red", style="dotted") >> redis1_service
    
    # Security Group Associations
    public_sg >> Edge(style="dashed", color="gray") >> bastion
    private_sg >> Edge(style="dashed", color="gray") >> [redis1, redis2, redis3]
    
    # Route Table Associations
    public_rt >> Edge(style="dotted", color="gray") >> bastion
    private_rt >> Edge(style="dotted", color="gray") >> [redis1, redis2, redis3]

print("✅ Redis Infrastructure Architecture Diagram created successfully!")
print("📁 File saved as: redis_infrastructure_architecture.png")
print("🔍 The diagram shows the complete AWS infrastructure with networking details")
