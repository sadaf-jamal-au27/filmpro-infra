#!/bin/bash
set -e

echo "🔄 Setting up Terraform remote state backend..."

# Use fixed bucket name to match backend.tf
BUCKET_NAME="filmpro-terraform-state-20240916"

# Check if bucket already exists
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ S3 bucket already exists: $BUCKET_NAME"
else
    echo "📦 Creating S3 bucket: $BUCKET_NAME"
    
    # Create S3 bucket for state
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
fi

echo "📝 Backend configuration ready!"
echo ""
echo "Next steps:"
echo "1. Run: terraform init"
echo "2. Run: terraform apply"
