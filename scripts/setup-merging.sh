#!/bin/bash

# Branch Protection and Merging Strategy Setup Script
# This script helps configure repository settings for the merging strategy

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "${BLUE}🔧 $1${NC}"
    echo "=================================================="
}

# Check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is required but not installed."
        print_info "Install it from: https://cli.github.com/"
        print_info "Or use: brew install gh (on macOS)"
        exit 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated."
        print_info "Run: gh auth login"
        exit 1
    fi
    
    print_success "GitHub CLI is installed and authenticated"
}

# Get repository information
get_repo_info() {
    REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
    REPO_NAME=$(gh repo view --json name --jq '.name')
    
    print_info "Repository: $REPO_OWNER/$REPO_NAME"
}

# Create CODEOWNERS file
create_codeowners() {
    print_header "Creating CODEOWNERS File"
    
    if [ ! -f ".github/CODEOWNERS" ]; then
        mkdir -p .github
        cat > .github/CODEOWNERS << EOF
# Global owners - these users will be requested for review when someone opens a pull request
* @$REPO_OWNER

# Terraform configuration files
*.tf @$REPO_OWNER
*.tfvars @$REPO_OWNER

# CI/CD pipeline files
.github/workflows/ @$REPO_OWNER

# Documentation
*.md @$REPO_OWNER

# Scripts
scripts/ @$REPO_OWNER

# Infrastructure-specific files
main.tf @$REPO_OWNER
provider.tf @$REPO_OWNER
variables.tf @$REPO_OWNER
outputs.tf @$REPO_OWNER
EOF
        print_success "CODEOWNERS file created"
    else
        print_info "CODEOWNERS file already exists"
    fi
}

# Create GitHub environments
create_environments() {
    print_header "Creating GitHub Environments"
    
    # Create staging environment
    print_info "Creating staging environment..."
    gh api repos/$REPO_OWNER/$REPO_NAME/environments/staging \
        --method PUT \
        --field wait_timer=0 \
        --field prevent_self_review=false \
        --field reviewers='[]' || print_warning "Staging environment may already exist"
    
    # Create production environment with protection
    print_info "Creating production environment..."
    gh api repos/$REPO_OWNER/$REPO_NAME/environments/production \
        --method PUT \
        --field wait_timer=300 \
        --field prevent_self_review=true \
        --field reviewers="[{\"type\":\"User\",\"id\":$(gh api user --jq '.id')}]" || print_warning "Production environment may already exist"
    
    print_success "Environments configured"
}

# Set up branch protection rules
setup_branch_protection() {
    print_header "Setting Up Branch Protection Rules"
    
    print_info "Configuring master branch protection..."
    
    # Master branch protection
    gh api repos/$REPO_OWNER/$REPO_NAME/branches/master/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["Terraform Validation and Security"]}' \
        --field enforce_admins=true \
        --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
        --field restrictions=null \
        --field required_linear_history=true \
        --field allow_force_pushes=false \
        --field allow_deletions=false || print_error "Failed to set master branch protection"
    
    print_info "Configuring develop branch protection..."
    
    # Develop branch protection
    gh api repos/$REPO_OWNER/$REPO_NAME/branches/develop/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["Terraform Validation and Security"]}' \
        --field enforce_admins=false \
        --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
        --field restrictions=null \
        --field required_linear_history=false \
        --field allow_force_pushes=true \
        --field allow_deletions=false || print_error "Failed to set develop branch protection"
    
    print_success "Branch protection rules configured"
}

# Create develop branch if it doesn't exist
create_develop_branch() {
    print_header "Setting Up Development Branch"
    
    if ! git show-ref --verify --quiet refs/heads/develop; then
        print_info "Creating develop branch..."
        git checkout -b develop
        git push -u origin develop
        git checkout master
        print_success "Develop branch created and pushed"
    else
        print_info "Develop branch already exists"
    fi
}

# Configure repository settings
configure_repo_settings() {
    print_header "Configuring Repository Settings"
    
    # Enable merge options
    gh api repos/$REPO_OWNER/$REPO_NAME \
        --method PATCH \
        --field allow_merge_commit=true \
        --field allow_squash_merge=true \
        --field allow_rebase_merge=true \
        --field delete_branch_on_merge=true \
        --field allow_auto_merge=true || print_warning "Some settings may not have been applied"
    
    print_success "Repository settings configured"
}

# Display setup instructions
display_manual_steps() {
    print_header "Manual Setup Required"
    
    echo -e "${YELLOW}The following steps must be completed manually in the GitHub web interface:${NC}"
    echo
    echo "1. Go to: https://github.com/$REPO_OWNER/$REPO_NAME/settings/branches"
    echo "   - Verify branch protection rules are correctly applied"
    echo "   - Add any additional status checks as they become available"
    echo
    echo "2. Go to: https://github.com/$REPO_OWNER/$REPO_NAME/settings/environments"
    echo "   - Verify environments are created with correct protection rules"
    echo "   - Add additional reviewers if needed"
    echo
    echo "3. Go to: https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets/actions"
    echo "   - Add AWS_ACCESS_KEY_ID secret"
    echo "   - Add AWS_SECRET_ACCESS_KEY secret"
    echo
    echo "4. Test the workflow by creating a feature branch and pull request"
    echo
    echo -e "${GREEN}For detailed instructions, see: MERGING_SETUP.md${NC}"
}

# Verify current setup
verify_setup() {
    print_header "Verifying Current Setup"
    
    # Check branch protection
    print_info "Checking master branch protection..."
    if gh api repos/$REPO_OWNER/$REPO_NAME/branches/master/protection &> /dev/null; then
        print_success "Master branch is protected"
    else
        print_warning "Master branch protection not found"
    fi
    
    # Check environments
    print_info "Checking environments..."
    ENVS=$(gh api repos/$REPO_OWNER/$REPO_NAME/environments --jq '.environments[].name' | tr '\n' ' ')
    if [[ $ENVS == *"staging"* && $ENVS == *"production"* ]]; then
        print_success "Required environments exist: $ENVS"
    else
        print_warning "Some environments may be missing: $ENVS"
    fi
    
    # Check secrets
    print_info "Checking repository secrets..."
    SECRETS=$(gh secret list --repo $REPO_OWNER/$REPO_NAME | grep -c "AWS_" || echo "0")
    if [ "$SECRETS" -ge 2 ]; then
        print_success "AWS secrets are configured"
    else
        print_warning "AWS secrets may be missing (found: $SECRETS)"
    fi
}

# Test workflow
test_workflow() {
    print_header "Testing Workflow Setup"
    
    print_info "You can test the setup by:"
    echo "1. Creating a feature branch:"
    echo "   git checkout develop"
    echo "   git checkout -b feature/test-workflow"
    echo
    echo "2. Making a small change:"
    echo "   echo '# Test change' >> README.md"
    echo "   git add README.md"
    echo "   git commit -m 'test: verify workflow configuration'"
    echo
    echo "3. Pushing and creating a PR:"
    echo "   git push origin feature/test-workflow"
    echo "   gh pr create --base develop --title 'Test workflow' --body 'Testing branch protection and CI/CD'"
    echo
    echo "4. Observe the automated checks and protection rules in action"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 FilmPro Infrastructure - Merging Strategy Setup${NC}"
    echo "======================================================="
    echo
    
    check_gh_cli
    get_repo_info
    echo
    
    create_codeowners
    echo
    
    create_develop_branch
    echo
    
    create_environments
    echo
    
    setup_branch_protection
    echo
    
    configure_repo_settings
    echo
    
    verify_setup
    echo
    
    display_manual_steps
    echo
    
    test_workflow
    echo
    
    print_success "🎉 Automated setup complete!"
    print_info "Please complete the manual steps and test the workflow."
}

# Handle command line arguments
case "${1:-setup}" in
    "setup")
        main
        ;;
    "verify")
        check_gh_cli
        get_repo_info
        verify_setup
        ;;
    "test")
        test_workflow
        ;;
    *)
        echo "Usage: $0 [setup|verify|test]"
        echo "  setup  - Run full setup (default)"
        echo "  verify - Check current configuration"
        echo "  test   - Show testing instructions"
        exit 1
        ;;
esac
