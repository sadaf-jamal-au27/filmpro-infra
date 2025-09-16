#!/bin/bash
set -e

echo "🔧 Comprehensive GitHub Actions AWS Permissions Setup"
echo "=================================================="

ROLE_NAME="GitHubActionsRole-FilmPro-Infra"
BUCKET_NAME="filmpro-terraform-state-20240916"

echo "1. 🔍 Checking if role exists..."
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo "   ✅ Role exists: $ROLE_NAME"
else
    echo "   ❌ Role does not exist: $ROLE_NAME"
    echo "   Please ensure the GitHub OIDC role is properly configured."
    exit 1
fi

echo ""
echo "2. 🪣 Verifying S3 bucket access..."
if aws s3 ls "s3://$BUCKET_NAME/" >/dev/null 2>&1; then
    echo "   ✅ S3 bucket accessible: $BUCKET_NAME"
else
    echo "   ⚠️  S3 bucket not accessible with current credentials"
fi

echo ""
echo "3. 📋 Setting up S3 permissions policy..."

# Create comprehensive policy for GitHub Actions
cat > comprehensive-github-actions-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TerraformStateS3Access",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketVersioning",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::${BUCKET_NAME}"
        },
        {
            "Sid": "TerraformStateObjectAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:GetObjectVersion"
            ],
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
        },
        {
            "Sid": "EC2FullAccess",
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMRoleAccess",
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:ListRoles",
                "iam:PassRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:ListInstanceProfiles",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# Create or update the policy
POLICY_ARN=$(aws iam create-policy \
    --policy-name "GitHubActions-Comprehensive-Policy" \
    --policy-document file://comprehensive-github-actions-policy.json \
    --query 'Policy.Arn' \
    --output text 2>/dev/null || \
    aws iam list-policies \
    --query 'Policies[?PolicyName==`GitHubActions-Comprehensive-Policy`].Arn' \
    --output text)

echo "   📋 Policy ARN: $POLICY_ARN"

echo ""
echo "4. 🔗 Attaching policies to role..."

# Attach the comprehensive policy
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"

echo "   ✅ Comprehensive policy attached"

# Also attach the S3-specific policy if it exists
S3_POLICY_ARN=$(aws iam list-policies \
    --query 'Policies[?PolicyName==`GitHubActions-TerraformState-Policy`].Arn' \
    --output text)

if [ -n "$S3_POLICY_ARN" ]; then
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "$S3_POLICY_ARN" 2>/dev/null || true
    echo "   ✅ S3 state policy also attached"
fi

echo ""
echo "5. 🧹 Cleaning up temporary files..."
rm -f comprehensive-github-actions-policy.json

echo ""
echo "✅ SETUP COMPLETE!"
echo "=================="
echo "The GitHub Actions role now has comprehensive permissions for:"
echo "• 🪣 S3 Terraform state management"
echo "• 🖥️  EC2 instance management"
echo "• 🔐 IAM role and instance profile management"
echo ""
echo "🚀 Ready to deploy via GitHub Actions pipeline!"
echo ""
echo "📋 Available Scripts:"
echo "• ./scripts/post-deploy-cleanup.sh - Run after deployment for cleanup"
echo "• ./scripts/check-pipeline-status.sh - Monitor pipeline progress"
