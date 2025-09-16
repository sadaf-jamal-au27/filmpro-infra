#!/bin/bash

# AWS OIDC Setup Script for GitHub Actions
# This script helps set up OIDC authentication between GitHub Actions and AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    print_success "AWS CLI is installed"
}

# Check if user is authenticated
check_aws_auth() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured or authenticated."
        echo "Run: aws configure"
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_success "Authenticated to AWS Account: $ACCOUNT_ID"
}

# Get GitHub repository information
get_repo_info() {
    echo ""
    print_status "Please provide your GitHub repository information:"
    
    read -p "GitHub Username/Organization: " GITHUB_USER
    read -p "Repository Name (default: FilmPro-Infra): " REPO_NAME
    REPO_NAME=${REPO_NAME:-FilmPro-Infra}
    
    GITHUB_REPO="$GITHUB_USER/$REPO_NAME"
    print_success "Repository: $GITHUB_REPO"
}

# Create OIDC Identity Provider
create_oidc_provider() {
    print_status "Creating OIDC Identity Provider..."
    
    # Check if provider already exists
    if aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)]' --output text | grep -q "token.actions.githubusercontent.com"; then
        print_warning "OIDC provider already exists"
        OIDC_PROVIDER_ARN=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)].Arn' --output text)
    else
        aws iam create-open-id-connect-provider \
            --url https://token.actions.githubusercontent.com \
            --client-id-list sts.amazonaws.com \
            --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 > /dev/null
        
        OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
        print_success "OIDC provider created: $OIDC_PROVIDER_ARN"
    fi
}

# Create trust policy
create_trust_policy() {
    print_status "Creating trust policy..."
    
    cat > github-actions-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "$OIDC_PROVIDER_ARN"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:$GITHUB_REPO:*"
                }
            }
        }
    ]
}
EOF
    
    print_success "Trust policy created: github-actions-trust-policy.json"
}

# Create IAM role
create_iam_role() {
    print_status "Creating IAM role for GitHub Actions..."
    
    ROLE_NAME="GitHubActionsRole-${REPO_NAME}"
    
    # Check if role already exists
    if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
        print_warning "IAM role $ROLE_NAME already exists"
    else
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file://github-actions-trust-policy.json > /dev/null
        
        print_success "IAM role created: $ROLE_NAME"
    fi
    
    ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
}

# Attach policies to role
attach_policies() {
    print_status "Attaching policies to IAM role..."
    
    # List of policies to attach
    POLICIES=(
        "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
        "arn:aws:iam::aws:policy/IAMFullAccess"
        "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
    )
    
    for policy in "${POLICIES[@]}"; do
        aws iam attach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "$policy" 2>/dev/null || true
        print_success "Attached policy: $(basename $policy)"
    done
}

# Display final configuration
display_config() {
    echo ""
    print_success "=== OIDC Setup Complete ==="
    echo ""
    echo "AWS Account ID: $ACCOUNT_ID"
    echo "GitHub Repository: $GITHUB_REPO"
    echo "IAM Role ARN: $ROLE_ARN"
    echo ""
    print_status "Next Steps:"
    echo "1. Add this secret to your GitHub repository:"
    echo "   Secret Name: AWS_ROLE_ARN"
    echo "   Secret Value: $ROLE_ARN"
    echo ""
    echo "2. Configure GitHub environments (staging, production)"
    echo "3. Set up branch protection rules"
    echo "4. Test the CI/CD pipeline"
    echo ""
    print_status "GitHub Repository Settings URL:"
    echo "https://github.com/$GITHUB_REPO/settings/secrets/actions"
    echo ""
    print_warning "Clean up: Remember to delete github-actions-trust-policy.json after setup"
}

# Main execution
main() {
    echo ""
    print_status "AWS OIDC Setup for GitHub Actions"
    echo "=================================="
    echo ""
    
    check_aws_cli
    check_aws_auth
    get_repo_info
    create_oidc_provider
    create_trust_policy
    create_iam_role
    attach_policies
    display_config
    
    echo ""
    print_success "Setup completed successfully!"
}

# Run the script
main "$@"
