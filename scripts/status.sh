#!/bin/bash

# Project Status and Setup Summary Script
# Shows current state and next steps for FilmPro-Infra

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

print_todo() {
    echo -e "${YELLOW}○${NC} $1"
}

print_warning() {
    echo -e "${RED}!${NC} $1"
}

# Check project files
check_files() {
    print_section "Project Files Status"
    
    local files=(
        "main.tf:Core infrastructure definition"
        "variables.tf:Input variables"
        "outputs.tf:Output definitions"
        "provider.tf:AWS provider configuration"
        "terraform.tfvars.example:Example configuration"
        "scripts/install_jenkins.sh:Jenkins installation script"
        "scripts/setup-dev.sh:Development setup script"
        "scripts/setup-merging.sh:Git merging setup script"
        "scripts/setup-aws-oidc.sh:AWS OIDC setup script"
        ".github/workflows/ci-cd.yml:CI/CD pipeline"
        ".github/pull_request_template.md:PR template"
        "README.md:Main documentation"
        "docs/GITHUB_SETUP.md:GitHub Actions setup guide"
        "docs/BRANCHING_STRATEGY.md:Git workflow documentation"
        "docs/MERGING_SETUP.md:Merge strategy setup"
        "docs/CHANGELOG.md:Version history"
        ".gitignore:Git ignore rules"
    )
    
    for file_desc in "${files[@]}"; do
        file=$(echo $file_desc | cut -d: -f1)
        desc=$(echo $file_desc | cut -d: -f2-)
        
        if [ -f "$file" ]; then
            print_status "$file - $desc"
        else
            print_warning "Missing: $file - $desc"
        fi
    done
}

# Check Git status
check_git() {
    print_section "Git Repository Status"
    
    if [ -d ".git" ]; then
        print_status "Git repository initialized"
        
        # Check current branch
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        echo "   Current branch: $current_branch"
        
        # Check if there are uncommitted changes
        if git diff-index --quiet HEAD -- 2>/dev/null; then
            print_status "Working directory clean"
        else
            print_warning "Uncommitted changes detected"
        fi
        
        # Check remotes
        remotes=$(git remote -v 2>/dev/null | wc -l)
        if [ $remotes -gt 0 ]; then
            print_status "Remote repositories configured"
        else
            print_todo "Configure remote repository"
        fi
    else
        print_warning "Git repository not initialized"
        echo "   Run: git init"
    fi
}

# Check AWS CLI
check_aws() {
    print_section "AWS Configuration Status"
    
    if command -v aws &> /dev/null; then
        print_status "AWS CLI installed"
        
        if aws sts get-caller-identity &> /dev/null; then
            account_id=$(aws sts get-caller-identity --query Account --output text)
            print_status "AWS authenticated (Account: $account_id)"
        else
            print_warning "AWS not authenticated"
            echo "   Run: aws configure"
        fi
    else
        print_warning "AWS CLI not installed"
        echo "   Install from: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    fi
}

# Check Terraform
check_terraform() {
    print_section "Terraform Status"
    
    if command -v terraform &> /dev/null; then
        version=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1)
        print_status "Terraform installed: $version"
        
        if [ -f ".terraform.lock.hcl" ]; then
            print_status "Terraform initialized"
        else
            print_todo "Run terraform init"
        fi
        
        if [ -f "terraform.tfvars" ]; then
            print_status "Configuration file exists"
        else
            print_todo "Copy and edit terraform.tfvars.example"
        fi
    else
        print_warning "Terraform not installed"
        echo "   Install from: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli"
    fi
}

# Show next steps
show_next_steps() {
    print_section "Next Steps for Production Deployment"
    
    echo ""
    echo "1. Repository Setup:"
    print_todo "Initialize git repository: git init"
    print_todo "Add remote: git remote add origin <your-repo-url>"
    print_todo "Push to GitHub: git push -u origin master"
    
    echo ""
    echo "2. AWS OIDC Configuration:"
    print_todo "Run: ./scripts/setup-aws-oidc.sh"
    print_todo "Follow prompts to configure AWS authentication"
    
    echo ""
    echo "3. GitHub Configuration:"
    print_todo "Create staging environment in GitHub"
    print_todo "Create production environment in GitHub"
    print_todo "Add AWS_ROLE_ARN secret"
    print_todo "Configure branch protection rules"
    
    echo ""
    echo "4. Infrastructure Deployment:"
    print_todo "Copy terraform.tfvars.example to terraform.tfvars"
    print_todo "Edit terraform.tfvars with your values"
    print_todo "Run: terraform init && terraform plan"
    print_todo "Deploy: terraform apply"
    
    echo ""
    echo "5. CI/CD Pipeline:"
    print_todo "Test with feature branch and PR"
    print_todo "Verify staging deployment on develop branch"
    print_todo "Verify production deployment on master branch"
}

# Show useful commands
show_commands() {
    print_section "Useful Commands"
    
    echo ""
    echo "Development Workflow:"
    echo "  git checkout -b feature/your-feature"
    echo "  # Make changes"
    echo "  git add . && git commit -m 'feat: your changes'"
    echo "  git push origin feature/your-feature"
    echo "  # Create PR to develop branch"
    
    echo ""
    echo "Infrastructure Management:"
    echo "  terraform plan                 # Preview changes"
    echo "  terraform apply               # Apply changes"
    echo "  terraform destroy             # Destroy infrastructure"
    echo "  terraform output              # Show outputs"
    
    echo ""
    echo "AWS Session Manager (Secure Access):"
    echo "  aws ssm start-session --target i-xxxxxxxxx"
    echo "  # Get instance ID from terraform output"
    
    echo ""
    echo "Setup Scripts:"
    echo "  ./scripts/setup-dev.sh        # Development environment"
    echo "  ./scripts/setup-aws-oidc.sh   # AWS OIDC configuration"
    echo "  ./scripts/setup-merging.sh    # Git merge strategies"
}

# Main execution
main() {
    clear
    print_header "FilmPro-Infra Project Status"
    
    check_files
    check_git
    check_aws
    check_terraform
    show_next_steps
    show_commands
    
    echo ""
    print_header "Documentation References"
    echo "README.md               - Main setup guide"
    echo "docs/GITHUB_SETUP.md    - GitHub Actions & OIDC setup"
    echo "docs/BRANCHING_STRATEGY.md - Git workflow"
    echo "docs/MERGING_SETUP.md   - Merge strategy configuration"
    echo "docs/CHANGELOG.md       - Version history"
    
    echo ""
    print_section "Support"
    echo "For issues or questions:"
    echo "1. Check the documentation files above"
    echo "2. Review error messages carefully"
    echo "3. Verify AWS permissions and quotas"
    echo "4. Check GitHub Actions logs for CI/CD issues"
    
    echo ""
    print_status "Project setup is complete and ready for deployment!"
}

# Run the script
main "$@"
