#!/usr/bin/env python3
"""
Redis Infrastructure Diagram Generator
Creates a comprehensive AWS infrastructure diagram for the Redis project
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch
import numpy as np

def create_infrastructure_diagram():
    # Create figure and axis
    fig, ax = plt.subplots(1, 1, figsize=(16, 12))
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 12)
    ax.axis('off')
    
    # Colors
    aws_orange = '#FF9900'
    aws_blue = '#232F3E'
    vpc_blue = '#4A90E2'
    public_green = '#7ED321'
    private_red = '#D0021B'
    security_purple = '#9013FE'
    
    # Title
    ax.text(8, 11.5, 'Redis Infrastructure on AWS', 
            fontsize=20, fontweight='bold', ha='center', color=aws_blue)
    ax.text(8, 11, 'Multi-AZ Redis Cluster with Bastion Host Architecture', 
            fontsize=14, ha='center', color='gray')
    
    # AWS Cloud boundary
    aws_cloud = FancyBboxPatch((0.5, 1), 15, 9.5, 
                               boxstyle="round,pad=0.1", 
                               facecolor='#F0F8FF', 
                               edgecolor=aws_orange, 
                               linewidth=3)
    ax.add_patch(aws_cloud)
    ax.text(1, 10.2, 'AWS Cloud (ap-south-1)', fontsize=12, fontweight='bold', color=aws_orange)
    
    # VPC
    vpc_box = FancyBboxPatch((1, 1.5), 14, 8.5, 
                             boxstyle="round,pad=0.1", 
                             facecolor='#E6F3FF', 
                             edgecolor=vpc_blue, 
                             linewidth=2)
    ax.add_patch(vpc_box)
    ax.text(1.5, 9.7, 'Custom VPC (10.0.0.0/16)', fontsize=12, fontweight='bold', color=vpc_blue)
    
    # Internet Gateway
    igw_box = FancyBboxPatch((7.5, 9), 1.5, 0.8, 
                             boxstyle="round,pad=0.05", 
                             facecolor=aws_orange, 
                             edgecolor='black')
    ax.add_patch(igw_box)
    ax.text(8.25, 9.4, 'IGW', fontsize=10, fontweight='bold', ha='center', color='white')
    
    # Public Subnet
    public_subnet = FancyBboxPatch((2, 7), 12, 1.8, 
                                   boxstyle="round,pad=0.1", 
                                   facecolor='#E8F5E8', 
                                   edgecolor=public_green, 
                                   linewidth=2)
    ax.add_patch(public_subnet)
    ax.text(2.5, 8.5, 'Public Subnet (10.0.1.0/24)', fontsize=11, fontweight='bold', color=public_green)
    
    # Bastion Host
    bastion_box = FancyBboxPatch((3, 7.3), 2, 1.2, 
                                 boxstyle="round,pad=0.05", 
                                 facecolor='white', 
                                 edgecolor='black')
    ax.add_patch(bastion_box)
    ax.text(4, 8.1, 'Bastion Host', fontsize=10, fontweight='bold', ha='center')
    ax.text(4, 7.8, 'EC2 t3.micro', fontsize=9, ha='center', color='gray')
    ax.text(4, 7.5, 'Public IP', fontsize=9, ha='center', color=public_green)
    
    # NAT Gateway
    nat_box = FancyBboxPatch((11, 7.3), 2, 1.2, 
                             boxstyle="round,pad=0.05", 
                             facecolor=aws_orange, 
                             edgecolor='black')
    ax.add_patch(nat_box)
    ax.text(12, 8.1, 'NAT Gateway', fontsize=10, fontweight='bold', ha='center', color='white')
    ax.text(12, 7.8, 'Elastic IP', fontsize=9, ha='center', color='white')
    
    # Private Subnets
    subnet_positions = [(2, 4.5), (6, 4.5), (10, 4.5)]
    subnet_azs = ['ap-south-1a', 'ap-south-1b', 'ap-south-1c']
    subnet_cidrs = ['10.0.2.0/24', '10.0.3.0/24', '10.0.4.0/24']
    
    for i, (x, y) in enumerate(subnet_positions):
        # Private subnet box
        private_subnet = FancyBboxPatch((x, y), 3.5, 2.5, 
                                        boxstyle="round,pad=0.1", 
                                        facecolor='#FFE8E8', 
                                        edgecolor=private_red, 
                                        linewidth=2)
        ax.add_patch(private_subnet)
        ax.text(x + 0.2, y + 2.2, f'Private Subnet', fontsize=10, fontweight='bold', color=private_red)
        ax.text(x + 0.2, y + 1.9, f'{subnet_cidrs[i]}', fontsize=9, color=private_red)
        ax.text(x + 0.2, y + 1.6, f'{subnet_azs[i]}', fontsize=9, color='gray')
        
        # Redis Node
        redis_box = FancyBboxPatch((x + 0.5, y + 0.3), 2.5, 1.2, 
                                   boxstyle="round,pad=0.05", 
                                   facecolor='#FF6B6B', 
                                   edgecolor='black')
        ax.add_patch(redis_box)
        ax.text(x + 1.75, y + 1.1, f'Redis Node {i+1}', fontsize=10, fontweight='bold', ha='center', color='white')
        ax.text(x + 1.75, y + 0.8, 'EC2 t3.micro', fontsize=9, ha='center', color='white')
        ax.text(x + 1.75, y + 0.5, 'Port: 6379', fontsize=9, ha='center', color='white')
    
    # Security Groups
    sg_box = FancyBboxPatch((1.5, 2), 4, 1.8, 
                            boxstyle="round,pad=0.1", 
                            facecolor='#F3E5F5', 
                            edgecolor=security_purple, 
                            linewidth=2)
    ax.add_patch(sg_box)
    ax.text(2, 3.5, 'Security Groups', fontsize=11, fontweight='bold', color=security_purple)
    ax.text(2, 3.1, '• Public SG: SSH(22), HTTP(80)', fontsize=9, color='black')
    ax.text(2, 2.8, '• Private SG: Redis(6379)', fontsize=9, color='black')
    ax.text(2, 2.5, '• Cluster: 16379-16384', fontsize=9, color='black')
    ax.text(2, 2.2, '• SSH access via Bastion', fontsize=9, color='black')
    
    # VPC Peering
    peering_box = FancyBboxPatch((10.5, 2), 4, 1.8, 
                                 boxstyle="round,pad=0.1", 
                                 facecolor='#E1F5FE', 
                                 edgecolor='#0277BD', 
                                 linewidth=2)
    ax.add_patch(peering_box)
    ax.text(11, 3.5, 'VPC Peering', fontsize=11, fontweight='bold', color='#0277BD')
    ax.text(11, 3.1, '• Cross-VPC Communication', fontsize=9, color='black')
    ax.text(11, 2.8, '• Route Table Updates', fontsize=9, color='black')
    ax.text(11, 2.5, '• Enhanced Connectivity', fontsize=9, color='black')
    
    # Connection arrows
    # Internet to IGW
    ax.annotate('', xy=(8.25, 9), xytext=(8.25, 10.5), 
                arrowprops=dict(arrowstyle='<->', color='blue', lw=2))
    ax.text(8.5, 9.8, 'Internet', fontsize=9, color='blue')
    
    # IGW to Bastion
    ax.annotate('', xy=(4, 8.5), xytext=(8, 9), 
                arrowprops=dict(arrowstyle='->', color='green', lw=2))
    
    # Bastion to Redis Nodes
    for i, (x, y) in enumerate(subnet_positions):
        ax.annotate('', xy=(x + 1.75, y + 1.5), xytext=(4.5, 7.3), 
                    arrowprops=dict(arrowstyle='->', color='red', lw=1.5, linestyle='--'))
    
    # NAT Gateway to Private Subnets
    for i, (x, y) in enumerate(subnet_positions):
        ax.annotate('', xy=(x + 3, y + 2), xytext=(11.5, 7.3), 
                    arrowprops=dict(arrowstyle='->', color='orange', lw=1.5))
    
    # Legend
    legend_elements = [
        patches.Patch(color=public_green, label='Public Subnet'),
        patches.Patch(color=private_red, label='Private Subnets'),
        patches.Patch(color=aws_orange, label='AWS Services'),
        patches.Patch(color=security_purple, label='Security Groups'),
        patches.Patch(color='#FF6B6B', label='Redis Nodes'),
        patches.Patch(color='#0277BD', label='VPC Peering')
    ]
    ax.legend(handles=legend_elements, loc='upper right', bbox_to_anchor=(0.98, 0.98))
    
    # Network flow indicators
    ax.text(0.5, 0.5, 'Network Flow:', fontsize=10, fontweight='bold')
    ax.text(0.5, 0.2, '→ SSH access via Bastion Host', fontsize=9, color='red')
    ax.text(4, 0.2, '→ Internet access via NAT Gateway', fontsize=9, color='orange')
    ax.text(8, 0.2, '→ Redis Cluster Communication', fontsize=9, color='purple')
    
    plt.tight_layout()
    return fig

def create_jenkins_pipeline_diagram():
    # Create figure for Jenkins Blue Ocean Pipeline
    fig, ax = plt.subplots(1, 1, figsize=(16, 10))
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 10)
    ax.axis('off')
    
    # Colors
    jenkins_blue = '#1f4e79'
    stage_green = '#4CAF50'
    stage_orange = '#FF9800'
    stage_red = '#F44336'
    stage_purple = '#9C27B0'
    
    # Title
    ax.text(8, 9.5, 'Jenkins Blue Ocean Pipeline - Redis Infrastructure', 
            fontsize=18, fontweight='bold', ha='center', color=jenkins_blue)
    ax.text(8, 9, 'Automated CI/CD Pipeline for Infrastructure Deployment', 
            fontsize=12, ha='center', color='gray')
    
    # Pipeline stages
    stages = [
        {'name': 'Checkout', 'color': stage_green, 'x': 1, 'desc': 'Git Clone\nRepository'},
        {'name': 'Validate', 'color': stage_orange, 'x': 3.5, 'desc': 'Terraform\nValidation'},
        {'name': 'Plan', 'color': stage_purple, 'x': 6, 'desc': 'Infrastructure\nPlanning'},
        {'name': 'Deploy', 'color': stage_red, 'x': 8.5, 'desc': 'Terraform\nApply'},
        {'name': 'Configure', 'color': stage_green, 'x': 11, 'desc': 'Ansible\nPlaybook'},
        {'name': 'Test', 'color': stage_orange, 'x': 13.5, 'desc': 'Health\nChecks'}
    ]
    
    # Draw pipeline flow
    for i, stage in enumerate(stages):
        # Stage box
        stage_box = FancyBboxPatch((stage['x']-0.6, 6), 1.2, 1.5, 
                                   boxstyle="round,pad=0.1", 
                                   facecolor=stage['color'], 
                                   edgecolor='black',
                                   linewidth=2)
        ax.add_patch(stage_box)
        
        # Stage name
        ax.text(stage['x'], 7, stage['name'], fontsize=11, fontweight='bold', 
                ha='center', va='center', color='white')
        
        # Stage description
        ax.text(stage['x'], 5.3, stage['desc'], fontsize=9, 
                ha='center', va='center', color='black')
        
        # Arrow to next stage
        if i < len(stages) - 1:
            ax.annotate('', xy=(stages[i+1]['x']-0.6, 6.75), xytext=(stage['x']+0.6, 6.75), 
                        arrowprops=dict(arrowstyle='->', color='black', lw=2))
    
    # Parallel execution branches
    ax.text(8, 4.5, 'Parallel Execution Branches', fontsize=14, fontweight='bold', ha='center', color=jenkins_blue)
    
    # Infrastructure branch
    infra_box = FancyBboxPatch((1, 2.5), 6, 1.5, 
                               boxstyle="round,pad=0.1", 
                               facecolor='#E3F2FD', 
                               edgecolor='#1976D2', 
                               linewidth=2)
    ax.add_patch(infra_box)
    ax.text(1.5, 3.7, 'Infrastructure Branch', fontsize=12, fontweight='bold', color='#1976D2')
    ax.text(1.5, 3.3, '• Terraform Init & Plan', fontsize=10, color='black')
    ax.text(1.5, 3.0, '• AWS Resource Creation', fontsize=10, color='black')
    ax.text(1.5, 2.7, '• VPC, Subnets, Security Groups', fontsize=10, color='black')
    
    # Configuration branch
    config_box = FancyBboxPatch((9, 2.5), 6, 1.5, 
                                boxstyle="round,pad=0.1", 
                                facecolor='#E8F5E8', 
                                edgecolor='#388E3C', 
                                linewidth=2)
    ax.add_patch(config_box)
    ax.text(9.5, 3.7, 'Configuration Branch', fontsize=12, fontweight='bold', color='#388E3C')
    ax.text(9.5, 3.3, '• Ansible Inventory Update', fontsize=10, color='black')
    ax.text(9.5, 3.0, '• Redis Installation & Setup', fontsize=10, color='black')
    ax.text(9.5, 2.7, '• Cluster Configuration', fontsize=10, color='black')
    
    # Pipeline parameters
    param_box = FancyBboxPatch((1, 0.5), 14, 1.5, 
                               boxstyle="round,pad=0.1", 
                               facecolor='#FFF3E0', 
                               edgecolor='#F57C00', 
                               linewidth=2)
    ax.add_patch(param_box)
    ax.text(1.5, 1.7, 'Pipeline Parameters & Features', fontsize=12, fontweight='bold', color='#F57C00')
    ax.text(1.5, 1.3, '• Action: apply/destroy  • Auto-approve: true/false  • SCM Polling: H/5 * * * *', fontsize=10, color='black')
    ax.text(1.5, 1.0, '• Notifications: Slack/Email  • Artifacts: Terraform State  • Rollback: Automatic on failure', fontsize=10, color='black')
    ax.text(1.5, 0.7, '• Blue Ocean UI: Visual pipeline monitoring  • Multi-branch support  • PR validation', fontsize=10, color='black')
    
    # Status indicators
    status_colors = ['#4CAF50', '#FF9800', '#F44336']
    status_labels = ['Success', 'In Progress', 'Failed']
    
    for i, (color, label) in enumerate(zip(status_colors, status_labels)):
        circle = plt.Circle((13 + i * 0.8, 8.5), 0.15, color=color)
        ax.add_patch(circle)
        ax.text(13 + i * 0.8, 8.1, label, fontsize=9, ha='center', color=color, fontweight='bold')
    
    plt.tight_layout()
    return fig

if __name__ == "__main__":
    # Create infrastructure diagram
    print("Creating infrastructure diagram...")
    infra_fig = create_infrastructure_diagram()
    infra_fig.savefig('/Users/shivam1355/Desktop/New_Redis/redis_infrastructure_diagram.png', 
                      dpi=300, bbox_inches='tight', facecolor='white')
    print("Infrastructure diagram saved as 'redis_infrastructure_diagram.png'")
    
    # Create Jenkins pipeline diagram
    print("Creating Jenkins Blue Ocean pipeline diagram...")
    pipeline_fig = create_jenkins_pipeline_diagram()
    pipeline_fig.savefig('/Users/shivam1355/Desktop/New_Redis/jenkins_blue_ocean_pipeline.png', 
                         dpi=300, bbox_inches='tight', facecolor='white')
    print("Jenkins pipeline diagram saved as 'jenkins_blue_ocean_pipeline.png'")
    
    print("\nDiagrams created successfully!")
    print("Files saved:")
    print("1. redis_infrastructure_diagram.png")
    print("2. jenkins_blue_ocean_pipeline.png")
