#!/usr/bin/env python3
"""
Jenkins Blue Ocean Flow Diagram Generator
Creates a detailed Blue Ocean pipeline visualization
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Circle, Rectangle
import numpy as np

def create_blue_ocean_flow():
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(18, 12))
    ax.set_xlim(0, 18)
    ax.set_ylim(0, 12)
    ax.axis('off')
    
    # Colors
    jenkins_blue = '#1f4e79'
    blue_ocean_blue = '#4A90E2'
    success_green = '#4CAF50'
    warning_orange = '#FF9800'
    error_red = '#F44336'
    
    # Title
    ax.text(9, 11.5, 'Jenkins Blue Ocean Pipeline Visualization', 
            fontsize=20, fontweight='bold', ha='center', color=jenkins_blue)
    ax.text(9, 11, 'Redis Infrastructure Deployment Pipeline', 
            fontsize=14, ha='center', color='gray')
    
    # Blue Ocean Interface mockup
    interface_box = FancyBboxPatch((0.5, 1), 17, 9.5, 
                                   boxstyle="round,pad=0.1", 
                                   facecolor='#F8F9FA', 
                                   edgecolor=blue_ocean_blue, 
                                   linewidth=3)
    ax.add_patch(interface_box)
    
    # Header bar
    header_box = Rectangle((0.5, 9.5), 17, 1, 
                          facecolor=jenkins_blue, 
                          edgecolor='none')
    ax.add_patch(header_box)
    ax.text(1, 10, 'Jenkins Blue Ocean', fontsize=14, fontweight='bold', color='white')
    ax.text(16, 10, 'Redis-Infrastructure-Pipeline', fontsize=12, ha='right', color='white')
    
    # Pipeline stages with Blue Ocean styling
    stages_data = [
        {'name': 'SCM', 'status': 'success', 'time': '15s', 'x': 2},
        {'name': 'Validate', 'status': 'success', 'time': '30s', 'x': 4.5},
        {'name': 'Plan', 'status': 'success', 'time': '45s', 'x': 7},
        {'name': 'Deploy', 'status': 'running', 'time': '2m 30s', 'x': 9.5},
        {'name': 'Configure', 'status': 'pending', 'time': '--', 'x': 12},
        {'name': 'Test', 'status': 'pending', 'time': '--', 'x': 14.5}
    ]
    
    status_colors = {
        'success': success_green,
        'running': warning_orange,
        'pending': '#E0E0E0',
        'failed': error_red
    }
    
    # Draw pipeline flow
    for i, stage in enumerate(stages_data):
        x = stage['x']
        color = status_colors[stage['status']]
        
        # Stage circle
        circle = Circle((x, 7.5), 0.4, facecolor=color, edgecolor='white', linewidth=3)
        ax.add_patch(circle)
        
        # Stage status icon
        if stage['status'] == 'success':
            ax.text(x, 7.5, '✓', fontsize=16, ha='center', va='center', color='white', fontweight='bold')
        elif stage['status'] == 'running':
            ax.text(x, 7.5, '⟳', fontsize=16, ha='center', va='center', color='white', fontweight='bold')
        elif stage['status'] == 'failed':
            ax.text(x, 7.5, '✗', fontsize=16, ha='center', va='center', color='white', fontweight='bold')
        
        # Stage name
        ax.text(x, 6.8, stage['name'], fontsize=11, fontweight='bold', ha='center', color='black')
        
        # Stage time
        ax.text(x, 6.4, stage['time'], fontsize=9, ha='center', color='gray')
        
        # Connection line to next stage
        if i < len(stages_data) - 1:
            next_x = stages_data[i+1]['x']
            line_color = color if stage['status'] == 'success' else '#E0E0E0'
            ax.plot([x + 0.4, next_x - 0.4], [7.5, 7.5], color=line_color, linewidth=4)
    
    # Parallel execution visualization
    ax.text(9, 5.8, 'Parallel Execution Details', fontsize=14, fontweight='bold', ha='center', color=jenkins_blue)
    
    # Infrastructure parallel branch
    infra_branch = FancyBboxPatch((1, 4.5), 7, 1, 
                                  boxstyle="round,pad=0.05", 
                                  facecolor='#E3F2FD', 
                                  edgecolor='#1976D2', 
                                  linewidth=2)
    ax.add_patch(infra_branch)
    ax.text(1.2, 5.2, 'Infrastructure Branch', fontsize=11, fontweight='bold', color='#1976D2')
    ax.text(1.2, 4.8, 'terraform init → terraform plan → terraform apply', fontsize=9, color='black')
    
    # Configuration parallel branch
    config_branch = FancyBboxPatch((10, 4.5), 7, 1, 
                                   boxstyle="round,pad=0.05", 
                                   facecolor='#E8F5E8', 
                                   edgecolor='#388E3C', 
                                   linewidth=2)
    ax.add_patch(config_branch)
    ax.text(10.2, 5.2, 'Configuration Branch', fontsize=11, fontweight='bold', color='#388E3C')
    ax.text(10.2, 4.8, 'ansible-inventory → ansible-playbook → health-check', fontsize=9, color='black')
    
    # Current execution details
    current_box = FancyBboxPatch((1, 3), 16, 1.2, 
                                 boxstyle="round,pad=0.1", 
                                 facecolor='#FFF3E0', 
                                 edgecolor=warning_orange, 
                                 linewidth=2)
    ax.add_patch(current_box)
    ax.text(1.5, 3.9, 'Currently Executing: Deploy Stage', fontsize=12, fontweight='bold', color=warning_orange)
    ax.text(1.5, 3.6, '• Creating VPC and subnets across multiple AZs', fontsize=10, color='black')
    ax.text(1.5, 3.3, '• Provisioning EC2 instances (1 bastion + 3 Redis nodes)', fontsize=10, color='black')
    ax.text(1.5, 3.0, '• Configuring security groups and network ACLs', fontsize=10, color='black')
    
    # Pipeline metrics
    metrics_box = FancyBboxPatch((1, 1.5), 7, 1.2, 
                                 boxstyle="round,pad=0.1", 
                                 facecolor='#F3E5F5', 
                                 edgecolor='#9C27B0', 
                                 linewidth=2)
    ax.add_patch(metrics_box)
    ax.text(1.5, 2.4, 'Pipeline Metrics', fontsize=12, fontweight='bold', color='#9C27B0')
    ax.text(1.5, 2.1, '• Build #47 | Duration: 4m 23s', fontsize=10, color='black')
    ax.text(1.5, 1.8, '• Success Rate: 94% (47/50)', fontsize=10, color='black')
    ax.text(1.5, 1.5, '• Avg Duration: 3m 45s', fontsize=10, color='black')
    
    # Environment info
    env_box = FancyBboxPatch((10, 1.5), 7, 1.2, 
                             boxstyle="round,pad=0.1", 
                             facecolor='#E1F5FE', 
                             edgecolor='#0277BD', 
                             linewidth=2)
    ax.add_patch(env_box)
    ax.text(10.5, 2.4, 'Environment Details', fontsize=12, fontweight='bold', color='#0277BD')
    ax.text(10.5, 2.1, '• Region: ap-south-1 (Mumbai)', fontsize=10, color='black')
    ax.text(10.5, 1.8, '• Instance Type: t3.micro', fontsize=10, color='black')
    ax.text(10.5, 1.5, '• Key Pair: redis-infra-key', fontsize=10, color='black')
    
    # Progress bar for current stage
    progress_bg = Rectangle((8.5, 8.2), 2, 0.2, facecolor='#E0E0E0', edgecolor='none')
    ax.add_patch(progress_bg)
    progress_fill = Rectangle((8.5, 8.2), 1.4, 0.2, facecolor=warning_orange, edgecolor='none')
    ax.add_patch(progress_fill)
    ax.text(9.5, 8.6, '70% Complete', fontsize=9, ha='center', color=warning_orange, fontweight='bold')
    
    plt.tight_layout()
    return fig

def create_pipeline_architecture():
    # Create architectural flow diagram
    fig, ax = plt.subplots(1, 1, figsize=(16, 10))
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 10)
    ax.axis('off')
    
    # Title
    ax.text(8, 9.5, 'Jenkins Pipeline Architecture Flow', 
            fontsize=18, fontweight='bold', ha='center', color='#1f4e79')
    
    # Components
    components = [
        {'name': 'GitHub\nRepository', 'x': 2, 'y': 7, 'color': '#24292e'},
        {'name': 'Jenkins\nServer', 'x': 6, 'y': 7, 'color': '#1f4e79'},
        {'name': 'Terraform\nEngine', 'x': 10, 'y': 8, 'color': '#623CE4'},
        {'name': 'Ansible\nEngine', 'x': 10, 'y': 6, 'color': '#EE0000'},
        {'name': 'AWS\nInfrastructure', 'x': 14, 'y': 7, 'color': '#FF9900'}
    ]
    
    for comp in components:
        box = FancyBboxPatch((comp['x']-0.8, comp['y']-0.6), 1.6, 1.2, 
                             boxstyle="round,pad=0.1", 
                             facecolor=comp['color'], 
                             edgecolor='white',
                             linewidth=2)
        ax.add_patch(box)
        ax.text(comp['x'], comp['y'], comp['name'], fontsize=11, fontweight='bold', 
                ha='center', va='center', color='white')
    
    # Arrows showing flow
    arrows = [
        {'from': (2.8, 7), 'to': (5.2, 7), 'label': 'Webhook\nTrigger'},
        {'from': (6.8, 7.3), 'to': (9.2, 8), 'label': 'Infrastructure\nDeployment'},
        {'from': (6.8, 6.7), 'to': (9.2, 6), 'label': 'Configuration\nManagement'},
        {'from': (10.8, 7.5), 'to': (13.2, 7.2), 'label': 'AWS\nResources'},
        {'from': (10.8, 6.5), 'to': (13.2, 6.8), 'label': 'Server\nConfiguration'}
    ]
    
    for arrow in arrows:
        ax.annotate('', xy=arrow['to'], xytext=arrow['from'], 
                    arrowprops=dict(arrowstyle='->', color='#333', lw=2))
        mid_x = (arrow['from'][0] + arrow['to'][0]) / 2
        mid_y = (arrow['from'][1] + arrow['to'][1]) / 2 + 0.3
        ax.text(mid_x, mid_y, arrow['label'], fontsize=9, ha='center', 
                bbox=dict(boxstyle="round,pad=0.3", facecolor='white', edgecolor='gray'))
    
    # Process flow details
    flow_box = FancyBboxPatch((1, 2), 14, 2.5, 
                              boxstyle="round,pad=0.2", 
                              facecolor='#F8F9FA', 
                              edgecolor='#6C757D', 
                              linewidth=2)
    ax.add_patch(flow_box)
    ax.text(8, 4.2, 'Automated Pipeline Process Flow', fontsize=14, fontweight='bold', ha='center')
    
    flow_steps = [
        "1. Developer pushes code to GitHub repository",
        "2. GitHub webhook triggers Jenkins pipeline automatically",
        "3. Jenkins validates Terraform and Ansible configurations",
        "4. Terraform provisions AWS infrastructure (VPC, EC2, Security Groups)",
        "5. Ansible configures Redis cluster on provisioned instances",
        "6. Health checks verify successful deployment",
        "7. Notifications sent to team via Slack/Email"
    ]
    
    for i, step in enumerate(flow_steps):
        ax.text(1.5, 3.8 - i*0.2, step, fontsize=10, color='black')
    
    plt.tight_layout()
    return fig

if __name__ == "__main__":
    # Create Blue Ocean flow diagram
    print("Creating Blue Ocean flow diagram...")
    flow_fig = create_blue_ocean_flow()
    flow_fig.savefig('/Users/shivam1355/Desktop/New_Redis/jenkins_blue_ocean_flow.png', 
                     dpi=300, bbox_inches='tight', facecolor='white')
    print("Blue Ocean flow diagram saved as 'jenkins_blue_ocean_flow.png'")
    
    # Create pipeline architecture diagram
    print("Creating pipeline architecture diagram...")
    arch_fig = create_pipeline_architecture()
    arch_fig.savefig('/Users/shivam1355/Desktop/New_Redis/jenkins_pipeline_architecture.png', 
                     dpi=300, bbox_inches='tight', facecolor='white')
    print("Pipeline architecture diagram saved as 'jenkins_pipeline_architecture.png'")
    
    print("\nAll diagrams created successfully!")
    print("Files saved:")
    print("1. jenkins_blue_ocean_flow.png")
    print("2. jenkins_pipeline_architecture.png")
