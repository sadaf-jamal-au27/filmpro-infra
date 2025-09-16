#!/bin/bash

# GitHub Secret Verification Helper
# This script helps verify that the AWS_ROLE_ARN secret is properly configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

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

# Main function
main() {
    clear
    print_header "GitHub Secret Configuration Helper"
    
    echo ""
    print_info "This script will help you add the AWS_ROLE_ARN secret to fix the CI/CD pipeline."
    echo ""
    
    print_section "Required Secret Configuration"
    
    echo ""
    echo "Secret Name: AWS_ROLE_ARN"
    echo "Secret Value: arn:aws:iam::008099619893:role/GitHubActionsRole-FilmPro-Infra"
    echo ""
    
    print_section "Step-by-Step Instructions"
    
    echo ""
    echo "1. Open your GitHub repository:"
    echo "   https://github.com/sadaf-jamal-au27/filmpro-infra"
    echo ""
    echo "2. Navigate to Settings → Secrets and variables → Actions"
    echo ""
    echo "3. Click 'New repository secret'"
    echo ""
    echo "4. Enter the secret details:"
    echo "   Name: AWS_ROLE_ARN"
    echo "   Value: arn:aws:iam::008099619893:role/GitHubActionsRole-FilmPro-Infra"
    echo ""
    echo "5. Click 'Add secret'"
    echo ""
    
    print_section "Direct Links"
    
    echo ""
    echo "Repository Settings: https://github.com/sadaf-jamal-au27/filmpro-infra/settings"
    echo "Add Secret (Direct): https://github.com/sadaf-jamal-au27/filmpro-infra/settings/secrets/actions/new"
    echo ""
    
    print_section "Verification Steps"
    
    echo ""
    echo "After adding the secret:"
    echo ""
    echo "1. Go to Actions tab in your repository"
    echo "2. Create a test commit and push to trigger the workflow"
    echo "3. Check that the workflow runs without credential errors"
    echo ""
    
    print_section "Test Commands"
    
    echo ""
    echo "To test the pipeline after adding the secret:"
    echo ""
    echo "git checkout -b test/cicd-fix"
    echo "echo '# Test CI/CD fix' >> README.md"
    echo "git add README.md"
    echo "git commit -m 'test: verify CI/CD after adding AWS_ROLE_ARN secret'"
    echo "git push origin test/cicd-fix"
    echo ""
    echo "Then create a Pull Request from test/cicd-fix to develop"
    echo ""
    
    print_section "Common Issues"
    
    echo ""
    print_warning "If you still see credential errors after adding the secret:"
    echo ""
    echo "• Check that the secret name is exactly 'AWS_ROLE_ARN' (case-sensitive)"
    echo "• Verify the secret value has no extra spaces or line breaks"
    echo "• Make sure you're adding it as a repository secret, not environment secret"
    echo "• Wait a few minutes for GitHub to propagate the secret"
    echo ""
    
    print_section "Expected Results"
    
    echo ""
    print_status "After correct secret configuration:"
    echo "  • Pull Request workflows will run successfully"
    echo "  • Terraform plan will be generated and commented on PRs"
    echo "  • Staging deployment will work on develop branch"
    echo "  • Production deployment will work on master branch"
    echo ""
    
    print_header "Ready to Add Secret!"
    echo ""
    print_info "Follow the instructions above to add the AWS_ROLE_ARN secret to your repository."
    echo ""
}

# Run the script
main "$@"
