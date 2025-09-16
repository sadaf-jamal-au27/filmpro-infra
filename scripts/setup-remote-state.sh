#!/bin/bash
set -e

echo "🔄 Setting up Terraform remote state backend..."

# Create S3 bucket for state
BUCKET_NAME="filmpro-terraform-state-$(date +%s)"
aws s3api create-bucket --bucket "$BUCKET_NAME" --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Block public access
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "✅ S3 bucket created: $BUCKET_NAME"
echo "📝 Update backend.tf with this bucket name"
echo ""
echo "Next steps:"
echo "1. Update backend.tf bucket name to: $BUCKET_NAME"
echo "2. Run: terraform init"
echo "3. Run: terraform apply"
