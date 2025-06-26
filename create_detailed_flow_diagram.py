#!/usr/bin/env python3
"""
Detailed Jenkins Pipeline Flow Diagram
Shows the specific stages, conditions, and error handling
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.ci import Jenkins
from diagrams.onprem.vcs import Git
from diagrams.aws.compute import EC2
from diagrams.aws.network import VPC
from diagrams.aws.security import IAM
from diagrams.onprem.iac import Terraform
from diagrams.programming.language import Python
from diagrams.onprem.monitoring import Grafana
from diagrams.aws.storage import S3
from diagrams.generic.storage import Storage
from diagrams.onprem.inmemory import Redis
from diagrams.generic.device import Mobile
from diagrams.generic.blank import Blank

# Configure diagram
graph_attr = {
    "fontsize": "14",
    "bgcolor": "white",
    "pad": "1.0",
    "splines": "ortho",
    "rankdir": "TB"
}

with Diagram(
    "Jenkins Pipeline Detailed Flow",
    filename="jenkins_detailed_flow",
    show=False,
    direction="TB",
    graph_attr=graph_attr
):
    
    # Trigger
    trigger = Git("GitHub Push/SCM Poll")
    
    # Pipeline Start
    pipeline_start = Jenkins("Pipeline Triggered")
    
    # Stage 1: Clone
    with Cluster("Stage 1: Clone Repository"):
        clone_checkout = Python("Checkout SCM")
        clone_info = Python("Display Commit Info")
    
    # Stage 2: Pre-flight
    with Cluster("Stage 2: Pre-flight Checks"):
        check_aws = IAM("Check AWS Credentials")
        check_limits = IAM("Check Service Limits")
        check_resources = IAM("Check Existing Resources")
    
    # Stage 3: Key Setup
    with Cluster("Stage 3: Setup Key Pair"):
        key_check = Storage("Check Key Exists")
        key_create = Storage("Create/Recreate Key")
        key_update = Storage("Update Configs")
    
    # Stage 4: Terraform Plan
    with Cluster("Stage 4: Terraform Plan"):
        tf_init = Terraform("terraform init")
        tf_validate = Terraform("terraform validate")
        tf_plan = Terraform("terraform plan")
    
    # Conditional Stage 5
    with Cluster("Stage 5: Terraform Apply (if autoApprove)"):
        tf_apply = Terraform("terraform apply")
        tf_output = Terraform("terraform output")
    
    # Stage 6: Wait
    with Cluster("Stage 6: Wait for Infrastructure"):
        wait_instances = Mobile("Wait for Instances")
        wait_ssh = Mobile("Wait for SSH")
    
    # Stage 7: Ansible
    with Cluster("Stage 7: Ansible Configuration"):
        create_inventory = Redis("Create Dynamic Inventory")
        test_connectivity = Redis("Test SSH Connectivity")
        run_playbook = Redis("Run Ansible Playbook")
        verify_redis = Redis("Verify Redis Installation")
    
    # Stage 8: Verification
    with Cluster("Stage 8: Post-Deployment"):
        verify_instances = Grafana("Verify EC2 Instances")
        verify_vpc = Grafana("Verify VPC Resources")
        verify_security = Grafana("Verify Security Groups")
    
    # Stage 9: Artifacts
    with Cluster("Stage 9: Generate Artifacts"):
        gen_guide = S3("Generate Connection Guide")
        archive_key = S3("Archive SSH Key")
        archive_outputs = S3("Archive Terraform Outputs")
    
    # Error Handling
    with Cluster("Error Handling"):
        failure_diagnostics = Grafana("Failure Diagnostics")
        cleanup_resources = Storage("Cleanup Resources")
    
    # Success Path
    with Cluster("Success Path"):
        success_notification = Jenkins("Success Notification")
        deployment_complete = Jenkins("Deployment Complete")
    
    # Flow connections - Main Path
    trigger >> pipeline_start
    pipeline_start >> clone_checkout
    clone_checkout >> clone_info
    clone_info >> check_aws
    
    check_aws >> check_limits
    check_limits >> check_resources
    check_resources >> key_check
    
    key_check >> key_create
    key_create >> key_update
    key_update >> tf_init
    
    tf_init >> tf_validate
    tf_validate >> tf_plan
    tf_plan >> tf_apply
    
    tf_apply >> tf_output
    tf_output >> wait_instances
    wait_instances >> wait_ssh
    
    wait_ssh >> create_inventory
    create_inventory >> test_connectivity
    test_connectivity >> run_playbook
    run_playbook >> verify_redis
    
    verify_redis >> verify_instances
    verify_instances >> verify_vpc
    verify_vpc >> verify_security
    
    verify_security >> gen_guide
    gen_guide >> archive_key
    archive_key >> archive_outputs
    
    archive_outputs >> success_notification
    success_notification >> deployment_complete
    
    # Error Paths
    check_aws >> Edge(label="Fail", color="red", style="dashed") >> failure_diagnostics
    tf_plan >> Edge(label="Fail", color="red", style="dashed") >> failure_diagnostics
    tf_apply >> Edge(label="Fail", color="red", style="dashed") >> failure_diagnostics
    run_playbook >> Edge(label="Fail", color="red", style="dashed") >> failure_diagnostics
    
    failure_diagnostics >> cleanup_resources
    
    # Conditional Paths
    tf_plan >> Edge(label="Skip if not autoApprove", style="dotted") >> gen_guide

print("✅ Detailed Jenkins Pipeline Flow Diagram created successfully!")
print("📁 File saved as: jenkins_detailed_flow.png")
print("🔍 The diagram shows detailed stage flow, conditions, and error handling")
