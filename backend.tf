# Remote State Backend Configuration
# This file sets up S3 backend for Terraform state to avoid state conflicts

terraform {
  backend "s3" {
    bucket         = "filmpro-terraform-state-${random_suffix}"
    key            = "jenkins/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    
    # Uncomment and configure these for production
    # dynamodb_table = "terraform-lock-table"
    # versioning     = true
  }
}

# Random suffix for unique bucket name
resource "random_string" "state_suffix" {
  length  = 8
  special = false
  upper   = false
}
