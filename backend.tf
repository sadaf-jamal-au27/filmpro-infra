# Remote State Backend Configuration
# This file sets up S3 backend for Terraform state to avoid state conflicts

terraform {
  backend "s3" {
    bucket  = "filmpro-terraform-state-20240916"
    key     = "jenkins/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true

    # Uncomment and configure these for production
    # dynamodb_table = "terraform-lock-table"
    # versioning     = true
  }
}
