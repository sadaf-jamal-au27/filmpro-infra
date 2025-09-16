#!/bin/bash

# FilmPro Infrastructure - Development Setup Script
# This script sets up the local development environment and Git workflow

set -e

echo "🚀 Setting up FilmPro Infrastructure Development Environment"
echo "==========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    commands=("git" "terraform" "aws")
    missing_commands=()
    
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        echo "Please install the missing tools and run this script again."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Setup Git configuration
setup_git() {
    print_info "Setting up Git configuration..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository. Please run this script from the project root."
        exit 1
    fi
    
    # Set up Git hooks (optional)
    if [ ! -f ".git/hooks/pre-commit" ]; then
        cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for Terraform formatting

echo "Running pre-commit checks..."

# Check Terraform formatting
if ! terraform fmt -check -recursive; then
    echo "❌ Terraform files are not formatted correctly."
    echo "Run 'terraform fmt -recursive' to fix formatting."
    exit 1
fi

echo "✅ Pre-commit checks passed"
EOF
        chmod +x .git/hooks/pre-commit
        print_success "Git pre-commit hook installed"
    fi
    
    print_success "Git configuration complete"
}

# Setup Terraform
setup_terraform() {
    print_info "Setting up Terraform..."
    
    # Create terraform.tfvars if it doesn't exist
    if [ ! -f "terraform.tfvars" ]; then
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars
            print_success "Created terraform.tfvars from example"
            print_warning "Please edit terraform.tfvars with your specific values"
        else
            print_error "terraform.tfvars.example not found"
            exit 1
        fi
    fi
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    if terraform init; then
        print_success "Terraform initialized successfully"
    else
        print_error "Terraform initialization failed"
        exit 1
    fi
    
    # Validate Terraform configuration
    print_info "Validating Terraform configuration..."
    if terraform validate; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform validation failed"
        exit 1
    fi
    
    print_success "Terraform setup complete"
}

# Create development branches
setup_branches() {
    print_info "Setting up development branches..."
    
    # Check if we're on master
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "master" ]; then
        print_warning "Not on master branch. Currently on: $current_branch"
        read -p "Switch to master branch? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git checkout master
        fi
    fi
    
    # Create develop branch if it doesn't exist
    if ! git show-ref --verify --quiet refs/heads/develop; then
        print_info "Creating develop branch..."
        git checkout -b develop
        git push -u origin develop
        print_success "Develop branch created and pushed"
    else
        print_info "Develop branch already exists"
    fi
    
    print_success "Branch setup complete"
}

# Install development tools
install_dev_tools() {
    print_info "Installing development tools..."
    
    # Check if Python is available for Checkov
    if command -v python3 &> /dev/null; then
        if ! command -v checkov &> /dev/null; then
            print_info "Installing Checkov for security scanning..."
            pip3 install checkov
            print_success "Checkov installed"
        else
            print_info "Checkov already installed"
        fi
    else
        print_warning "Python3 not found. Checkov will not be installed."
    fi
    
    # Check if TFLint is available
    if ! command -v tflint &> /dev/null; then
        print_warning "TFLint not found. Consider installing it for additional Terraform linting."
        print_info "Install TFLint: https://github.com/terraform-linters/tflint#installation"
    else
        print_success "TFLint is available"
    fi
    
    print_success "Development tools setup complete"
}

# Validate AWS configuration
validate_aws() {
    print_info "Validating AWS configuration..."
    
    if aws sts get-caller-identity > /dev/null 2>&1; then
        aws_account=$(aws sts get-caller-identity --query Account --output text)
        aws_user=$(aws sts get-caller-identity --query Arn --output text)
        print_success "AWS configuration is valid"
        print_info "AWS Account: $aws_account"
        print_info "AWS User/Role: $aws_user"
    else
        print_error "AWS configuration is invalid or not set up"
        print_info "Please run 'aws configure' to set up your AWS credentials"
        exit 1
    fi
}

# Main setup function
main() {
    echo
    print_info "Starting development environment setup..."
    echo
    
    check_prerequisites
    echo
    
    setup_git
    echo
    
    setup_terraform
    echo
    
    validate_aws
    echo
    
    setup_branches
    echo
    
    install_dev_tools
    echo
    
    print_success "🎉 Development environment setup complete!"
    echo
    print_info "Next steps:"
    echo "1. Edit terraform.tfvars with your specific configuration"
    echo "2. Run 'terraform plan' to review infrastructure changes"
    echo "3. Create a feature branch: git checkout -b feature/your-feature-name"
    echo "4. Make your changes and commit them"
    echo "5. Push and create a pull request"
    echo
    print_info "Available commands:"
    echo "- terraform plan    : Preview infrastructure changes"
    echo "- terraform apply   : Apply infrastructure changes"
    echo "- terraform destroy : Destroy infrastructure"
    echo "- checkov -f .      : Run security scan"
    echo
    print_warning "Remember: Never commit terraform.tfvars or .terraform/ directory!"
}

# Run main function
main "$@"
