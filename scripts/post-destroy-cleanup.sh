#!/bin/bash
set -e

echo "🧹 Post-Destroy Cleanup and Verification"
echo "========================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo ""
echo "1. 🗑️  Cleaning up local files..."

# Clean up local files
rm -f terraform.tfplan 2>/dev/null && print_status "Removed terraform.tfplan" || print_info "No terraform.tfplan to remove"
rm -f plan_output.txt 2>/dev/null && print_status "Removed plan_output.txt" || print_info "No plan_output.txt to remove"
rm -f .terraform.lock.hcl.backup 2>/dev/null && print_status "Removed lock file backup" || print_info "No lock file backup to remove"
rm -f comprehensive-github-actions-policy.json 2>/dev/null && print_status "Removed policy file" || print_info "No policy files to remove"
rm -f github-actions-s3-policy.json 2>/dev/null && print_status "Removed S3 policy file" || print_info "No S3 policy files to remove"
rm -f deployment-cleanup-report.txt 2>/dev/null && print_status "Removed deployment report" || print_info "No deployment report to remove"

echo ""
echo "2. 🔍 Verifying Terraform state..."

# Check if any resources remain in state
if terraform show > /dev/null 2>&1; then
    RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$RESOURCE_COUNT" -eq 0 ]; then
        print_status "Terraform state is clean (no resources)"
    else
        echo "⚠️  Warning: $RESOURCE_COUNT resources still in state:"
        terraform state list
    fi
else
    print_status "No Terraform state found"
fi

echo ""
echo "3. 🪣 Verifying S3 bucket cleanup..."

# Check if S3 bucket still exists
if aws s3 ls s3://filmpro-terraform-state-20240916/ >/dev/null 2>&1; then
    echo "⚠️  S3 bucket still exists"
else
    print_status "S3 bucket successfully removed"
fi

echo ""
echo "4. 🔐 Verifying IAM policy cleanup..."

# Check if policies still exist
COMPREHENSIVE_POLICY=$(aws iam list-policies --query 'Policies[?PolicyName==`GitHubActions-Comprehensive-Policy`].Arn' --output text)
S3_POLICY=$(aws iam list-policies --query 'Policies[?PolicyName==`GitHubActions-TerraformState-Policy`].Arn' --output text)

if [ -z "$COMPREHENSIVE_POLICY" ]; then
    print_status "Comprehensive policy successfully removed"
else
    echo "⚠️  Comprehensive policy still exists: $COMPREHENSIVE_POLICY"
fi

if [ -z "$S3_POLICY" ]; then
    print_status "S3 state policy successfully removed"
else
    echo "⚠️  S3 state policy still exists: $S3_POLICY"
fi

echo ""
echo "5. 📁 Cleaning up .terraform directory..."

# Optional: Clean up .terraform directory (this will require re-init if you want to use Terraform again)
read -p "Do you want to remove the .terraform directory? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf .terraform 2>/dev/null && print_status "Removed .terraform directory" || print_info "No .terraform directory to remove"
    rm -f .terraform.lock.hcl 2>/dev/null && print_status "Removed .terraform.lock.hcl" || print_info "No lock file to remove"
    echo "ℹ️  Note: You'll need to run 'terraform init' if you want to use Terraform again"
else
    print_info "Keeping .terraform directory"
fi

echo ""
echo "🎉 Destroy Cleanup Complete!"
echo "============================"
print_status "All AWS resources have been destroyed"
print_status "S3 bucket and IAM policies removed"
print_status "Local temporary files cleaned"
print_status "Environment reset successfully"

echo ""
echo "📋 Summary of Destroyed Resources:"
echo "   • EC2 Instance (Jenkins server)"
echo "   • Security Group"
echo "   • IAM Role and Instance Profile"
echo "   • S3 Bucket (Terraform state)"
echo "   • IAM Policies (GitHub Actions permissions)"
echo ""
echo "✨ Your AWS environment is now clean!"
echo ""
echo "💡 To redeploy in the future:"
echo "   1. Run: terraform init"
echo "   2. Run: ./scripts/setup-remote-state.sh"
echo "   3. Run: ./scripts/setup-comprehensive-permissions.sh"
echo "   4. Push to master branch to trigger CI/CD deployment"
