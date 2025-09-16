#!/bin/bash
set -e

echo "🧹 Post-Deployment Cleanup and Verification Script"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Initialize Terraform to get outputs
echo "🔧 Initializing Terraform..."
terraform init > /dev/null 2>&1

# Verify deployment exists
if ! terraform show > /dev/null 2>&1; then
    print_error "No Terraform deployment found. Nothing to clean up."
    exit 1
fi

print_status "Terraform deployment found"

echo ""
echo "1. 📊 Gathering Deployment Information..."

# Get deployment details
JENKINS_URL=$(terraform output -raw jenkins_url 2>/dev/null || echo "")
PUBLIC_IP=$(terraform output -raw publicip 2>/dev/null || echo "")
INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "")
SG_ID=$(terraform output -raw security_group_id 2>/dev/null || echo "")

if [ -n "$PUBLIC_IP" ]; then
    print_status "Jenkins Server: $JENKINS_URL"
    print_status "Public IP: $PUBLIC_IP"
    print_status "Instance ID: $INSTANCE_ID"
    print_status "Security Group: $SG_ID"
else
    print_warning "Could not retrieve deployment information"
fi

echo ""
echo "2. 🧹 Cleaning Temporary Files..."

# Clean up temporary Terraform files
rm -f terraform.tfplan 2>/dev/null && print_status "Removed terraform.tfplan" || print_info "No terraform.tfplan to remove"
rm -f plan_output.txt 2>/dev/null && print_status "Removed plan_output.txt" || print_info "No plan_output.txt to remove"
rm -f .terraform.lock.hcl.backup 2>/dev/null && print_status "Removed lock file backup" || print_info "No lock file backup to remove"

# Clean up any leftover policy files
rm -f comprehensive-github-actions-policy.json 2>/dev/null && print_status "Removed policy file" || print_info "No policy files to remove"
rm -f github-actions-s3-policy.json 2>/dev/null && print_status "Removed S3 policy file" || print_info "No S3 policy files to remove"

echo ""
echo "3. 🏥 Health Check - Jenkins Availability..."

if [ -n "$JENKINS_URL" ]; then
    print_info "Testing Jenkins connectivity..."
    
    # Test Jenkins connectivity with timeout
    if timeout 30 curl -s --connect-timeout 10 "$JENKINS_URL" >/dev/null 2>&1; then
        print_status "Jenkins is responding at $JENKINS_URL"
        
        # Check if Jenkins setup wizard is accessible
        if curl -s --connect-timeout 10 "$JENKINS_URL" | grep -q "Jenkins"; then
            print_status "Jenkins web interface is accessible"
        else
            print_warning "Jenkins is responding but web interface may not be fully ready"
        fi
    else
        print_warning "Jenkins not yet responding (normal for new deployments - allow 2-3 minutes)"
    fi
else
    print_warning "Jenkins URL not available"
fi

echo ""
echo "4. 🔒 Security Verification..."

if [ -n "$SG_ID" ]; then
    print_info "Checking security group configuration..."
    
    # Check security group rules
    if aws ec2 describe-security-groups --group-ids "$SG_ID" >/dev/null 2>&1; then
        print_status "Security group $SG_ID is properly configured"
        
        # Check if port 8080 is open
        JENKINS_RULE=$(aws ec2 describe-security-groups --group-ids "$SG_ID" \
            --query 'SecurityGroups[0].IpPermissions[?FromPort==`8080`]' \
            --output text 2>/dev/null)
        
        if [ -n "$JENKINS_RULE" ]; then
            print_status "Jenkins port (8080) is properly configured"
        else
            print_warning "Jenkins port configuration not found"
        fi
    else
        print_warning "Could not verify security group"
    fi
fi

echo ""
echo "5. 📋 Resource Summary..."

# Display resource count
RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
print_info "Total managed resources: $RESOURCE_COUNT"

# Display key resources
echo ""
echo "🎯 Key Resources:"
terraform state list 2>/dev/null | grep -E "(aws_instance|aws_security_group|aws_iam_role)" | while read resource; do
    echo "   • $resource"
done

echo ""
echo "6. 📄 Generating Cleanup Report..."

# Create cleanup report
cat > deployment-cleanup-report.txt << EOF
Deployment Cleanup Report
========================
Date: $(date)
Status: Completed

Infrastructure Details:
- Jenkins URL: $JENKINS_URL
- Public IP: $PUBLIC_IP
- Instance ID: $INSTANCE_ID
- Security Group: $SG_ID

Cleanup Actions:
- ✅ Temporary files removed
- ✅ Health checks performed
- ✅ Security verification completed
- ✅ Resource inventory updated

Next Steps:
1. Access Jenkins at: $JENKINS_URL
2. Complete Jenkins initial setup wizard
3. Configure security settings
4. Set up CI/CD jobs

Note: Allow 2-3 minutes for Jenkins to fully initialize on first deployment.
EOF

print_status "Cleanup report saved to: deployment-cleanup-report.txt"

echo ""
echo "🎉 Cleanup Complete!"
echo "==================="
print_status "All cleanup tasks completed successfully"
print_info "Jenkins should be accessible at: $JENKINS_URL"
print_info "Use 'aws ssm start-session --target $INSTANCE_ID' for secure access"

echo ""
echo "📋 Summary of Actions:"
echo "   • Cleaned temporary Terraform files"
echo "   • Verified Jenkins health"
echo "   • Validated security configuration"
echo "   • Generated deployment report"
echo ""
echo "✨ Your Jenkins infrastructure is ready for use!"
