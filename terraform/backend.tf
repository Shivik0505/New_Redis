# Terraform Backend Configuration
# Uncomment and configure the following if you want to store state remotely in S3
# This is recommended for production environments

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"   # Replace with your S3 bucket name
#     key            = "redis-demo/terraform.tfstate"     
#     region         = "ap-south-1"              
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"    # Optional: for state locking
#   }
# }

# For local development, state will be stored in terraform.tfstate file
# Make sure to add terraform.tfstate* to .gitignore to avoid committing sensitive data
