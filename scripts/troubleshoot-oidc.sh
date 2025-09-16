#!/bin/bash

# GitHub Actions OIDC Troubleshooting Script
# This script helps diagnose and fix common OIDC authentication issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_section() {
    echo -e "\n${BLUE}$1${NC}"
    echo "----------------------------"
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check AWS CLI and authentication
check_aws_setup() {
    print_section "AWS Configuration Check"
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        return 1
    fi
    print_status "AWS CLI is installed"
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not authenticated"
        return 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    print_status "AWS authenticated as: $USER_ARN"
    print_status "Account ID: $ACCOUNT_ID"
    
    echo "$ACCOUNT_ID" > /tmp/aws_account_id
}

# Check OIDC Identity Provider
check_oidc_provider() {
    print_section "OIDC Identity Provider Check"
    
    ACCOUNT_ID=$(cat /tmp/aws_account_id)
    
    # Check if OIDC provider exists
    if aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)]' --output text | grep -q "token.actions.githubusercontent.com"; then
        print_status "OIDC Identity Provider exists"
        OIDC_PROVIDER_ARN=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)].Arn' --output text)
        print_info "Provider ARN: $OIDC_PROVIDER_ARN"
    else
        print_error "OIDC Identity Provider not found"
        print_info "Run: ./scripts/setup-aws-oidc.sh to create it"
        return 1
    fi
}

# Check IAM Role
check_iam_role() {
    print_section "IAM Role Check"
    
    # Try common role names
    ROLE_NAMES=(
        "GitHubActionsRole"
        "GitHubActionsRole-FilmPro-Infra"
        "GitHubActionsRole-filmpro-infra"
    )
    
    FOUND_ROLE=""
    for role_name in "${ROLE_NAMES[@]}"; do
        if aws iam get-role --role-name "$role_name" &> /dev/null; then
            FOUND_ROLE="$role_name"
            break
        fi
    done
    
    if [ -n "$FOUND_ROLE" ]; then
        print_status "Found IAM Role: $FOUND_ROLE"
        ACCOUNT_ID=$(cat /tmp/aws_account_id)
        ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${FOUND_ROLE}"
        print_info "Role ARN: $ROLE_ARN"
        
        # Check trust policy
        print_info "Checking trust policy..."
        TRUST_POLICY=$(aws iam get-role --role-name "$FOUND_ROLE" --query 'Role.AssumeRolePolicyDocument' --output text)
        if echo "$TRUST_POLICY" | grep -q "token.actions.githubusercontent.com"; then
            print_status "Trust policy allows GitHub Actions"
        else
            print_error "Trust policy doesn't allow GitHub Actions"
        fi
        
        echo "$ROLE_ARN" > /tmp/role_arn
    else
        print_error "No GitHub Actions IAM Role found"
        print_info "Run: ./scripts/setup-aws-oidc.sh to create it"
        return 1
    fi
}

# Check GitHub repository setup
check_github_repo() {
    print_section "GitHub Repository Check"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        return 1
    fi
    print_status "In a git repository"
    
    # Check for remote origin
    if git remote get-url origin > /dev/null 2>&1; then
        REMOTE_URL=$(git remote get-url origin)
        print_status "Remote origin: $REMOTE_URL"
        
        # Extract GitHub repo info
        if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
            GITHUB_OWNER="${BASH_REMATCH[1]}"
            GITHUB_REPO="${BASH_REMATCH[2]}"
            print_info "GitHub Owner: $GITHUB_OWNER"
            print_info "GitHub Repo: $GITHUB_REPO"
            
            echo "${GITHUB_OWNER}/${GITHUB_REPO}" > /tmp/github_repo
        else
            print_warning "Could not parse GitHub repository from remote URL"
        fi
    else
        print_error "No remote origin configured"
        return 1
    fi
}

# Check workflow file
check_workflow() {
    print_section "GitHub Actions Workflow Check"
    
    WORKFLOW_FILE=".github/workflows/ci-cd.yml"
    if [ -f "$WORKFLOW_FILE" ]; then
        print_status "Workflow file exists: $WORKFLOW_FILE"
        
        # Check for OIDC permissions
        if grep -q "id-token: write" "$WORKFLOW_FILE"; then
            print_status "OIDC permissions configured"
        else
            print_error "OIDC permissions missing"
        fi
        
        # Check for role-to-assume
        if grep -q "role-to-assume:" "$WORKFLOW_FILE"; then
            print_status "role-to-assume parameter found"
        else
            print_error "role-to-assume parameter missing"
        fi
        
        # Check for audience
        if grep -q "audience: sts.amazonaws.com" "$WORKFLOW_FILE"; then
            print_status "Correct audience configured"
        else
            print_warning "Audience parameter missing or incorrect"
        fi
    else
        print_error "Workflow file not found: $WORKFLOW_FILE"
        return 1
    fi
}

# Generate GitHub secret configuration
generate_github_secrets() {
    print_section "GitHub Secrets Configuration"
    
    if [ -f "/tmp/role_arn" ] && [ -f "/tmp/github_repo" ]; then
        ROLE_ARN=$(cat /tmp/role_arn)
        GITHUB_REPO=$(cat /tmp/github_repo)
        
        print_info "Add this secret to your GitHub repository:"
        echo ""
        echo "Repository: https://github.com/$GITHUB_REPO/settings/secrets/actions"
        echo ""
        echo "Secret Name: AWS_ROLE_ARN"
        echo "Secret Value: $ROLE_ARN"
        echo ""
        print_warning "Make sure to add this secret exactly as shown above!"
    else
        print_error "Could not determine role ARN or GitHub repository"
    fi
}

# Test OIDC configuration
test_oidc_config() {
    print_section "OIDC Configuration Test"
    
    if [ -f "/tmp/role_arn" ] && [ -f "/tmp/github_repo" ]; then
        ROLE_ARN=$(cat /tmp/role_arn)
        GITHUB_REPO=$(cat /tmp/github_repo)
        
        print_info "Testing OIDC configuration..."
        
        # Create a test assume role command (this won't work locally, but shows the format)
        echo ""
        echo "The following command would be used by GitHub Actions:"
        echo "aws sts assume-role-with-web-identity \\"
        echo "  --role-arn $ROLE_ARN \\"
        echo "  --role-session-name github-actions-test \\"
        echo "  --web-identity-token \$GITHUB_TOKEN \\"
        echo "  --duration-seconds 3600"
        echo ""
        print_info "This can only be tested from within GitHub Actions environment"
    fi
}

# Show common issues and solutions
show_troubleshooting() {
    print_section "Common Issues & Solutions"
    
    echo ""
    print_info "1. 'Error: Could not assume role'"
    echo "   - Check that AWS_ROLE_ARN secret is correctly set in GitHub"
    echo "   - Verify the role ARN format: arn:aws:iam::ACCOUNT:role/ROLE_NAME"
    echo "   - Ensure the trust policy allows your GitHub repository"
    echo ""
    
    print_info "2. 'Context access might be invalid: AWS_ROLE_ARN'"
    echo "   - This is just a linting warning, not an actual error"
    echo "   - The secret will be available at runtime in GitHub Actions"
    echo ""
    
    print_info "3. 'Environment protection rules'"
    echo "   - Go to GitHub → Settings → Environments"
    echo "   - Create 'staging' and 'production' environments"
    echo "   - Configure protection rules and required reviewers"
    echo ""
    
    print_info "4. 'OIDC provider not found'"
    echo "   - Run: ./scripts/setup-aws-oidc.sh"
    echo "   - Or manually create the OIDC provider in AWS IAM console"
    echo ""
    
    print_info "5. 'Permission denied errors'"
    echo "   - Ensure your AWS user has IAM permissions to create/modify roles"
    echo "   - Check that the GitHub Actions role has necessary AWS permissions"
}

# Main execution
main() {
    clear
    print_header "GitHub Actions OIDC Troubleshooter"
    
    echo ""
    print_info "This script will check your OIDC setup and help resolve common issues."
    echo ""
    
    # Run all checks
    if check_aws_setup && check_oidc_provider && check_iam_role && check_github_repo && check_workflow; then
        print_section "✅ All Checks Passed!"
        generate_github_secrets
        test_oidc_config
        echo ""
        print_status "Your OIDC setup appears to be correct!"
        print_info "If you're still having issues, check GitHub Actions logs for specific errors."
    else
        print_section "❌ Issues Found"
        echo ""
        print_warning "Some checks failed. Please address the issues above."
        print_info "You can run ./scripts/setup-aws-oidc.sh to fix most issues automatically."
    fi
    
    show_troubleshooting
    
    # Cleanup temp files
    rm -f /tmp/aws_account_id /tmp/role_arn /tmp/github_repo
    
    echo ""
    print_header "Troubleshooting Complete"
}

# Run the script
main "$@"
