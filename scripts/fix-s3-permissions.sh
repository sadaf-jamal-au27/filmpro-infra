#!/bin/bash
set -e

echo "🔧 Fixing GitHub Actions S3 permissions for Terraform state..."

# Get the GitHub Actions role ARN
ROLE_NAME="GitHubActionsRole-FilmPro-Infra"
BUCKET_NAME="filmpro-terraform-state-20240916"

# Create policy document for S3 access
cat > github-actions-s3-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketVersioning"
            ],
            "Resource": "arn:aws:s3:::${BUCKET_NAME}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
        }
    ]
}
EOF

# Create the policy
POLICY_ARN=$(aws iam create-policy \
    --policy-name "GitHubActions-TerraformState-Policy" \
    --policy-document file://github-actions-s3-policy.json \
    --query 'Policy.Arn' \
    --output text 2>/dev/null || \
    aws iam list-policies \
    --query 'Policies[?PolicyName==`GitHubActions-TerraformState-Policy`].Arn' \
    --output text)

echo "Policy ARN: $POLICY_ARN"

# Attach policy to the role
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"

echo "✅ S3 permissions added to GitHub Actions role"

# Clean up
rm -f github-actions-s3-policy.json

echo ""
echo "🔄 The GitHub Actions role now has access to the S3 bucket."
echo "🚀 Re-run the pipeline or wait for the current run to retry."
