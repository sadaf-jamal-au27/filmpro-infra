# Git Branching and Merging Strategies

This document outlines the branching model and merging strategies for the FilmPro Infrastructure project.

## Branching Strategy

We follow a **GitFlow-inspired** branching model adapted for infrastructure as code projects.

### Branch Types

#### 1. Main Branches

- **`master`** (Production)
  - Contains production-ready infrastructure code
  - All code here should be tested and validated
  - Protected branch with required reviews
  - Automatically deploys to production environment

- **`develop`** (Integration)
  - Integration branch for features
  - Contains the latest development changes
  - Used for staging environment deployments
  - Base branch for feature development

#### 2. Supporting Branches

- **`feature/*`** (Feature Development)
  - For developing new infrastructure features
  - Branch from: `develop`
  - Merge back to: `develop`
  - Naming: `feature/description` or `feature/ISSUE-123`
  - Examples:
    - `feature/add-monitoring`
    - `feature/update-security-groups`
    - `feature/jenkins-plugins`

- **`release/*`** (Release Preparation)
  - For preparing production releases
  - Branch from: `develop`
  - Merge to: `master` and `develop`
  - Naming: `release/v1.2.0`
  - Used for final testing and bug fixes

- **`hotfix/*`** (Production Fixes)
  - For critical production fixes
  - Branch from: `master`
  - Merge to: `master` and `develop`
  - Naming: `hotfix/critical-security-patch`

### Branch Protection Rules

#### Master Branch
- Require pull request reviews (minimum 1)
- Require status checks to pass
- Require branches to be up to date
- Require linear history
- No force pushes allowed
- No deletions allowed

#### Develop Branch
- Require pull request reviews (minimum 1)
- Require status checks to pass
- Allow force pushes by administrators only

## Workflow Examples

### 1. Feature Development Workflow

```bash
# Start feature development
git checkout develop
git pull origin develop
git checkout -b feature/add-monitoring

# Make changes and commit
git add .
git commit -m "Add CloudWatch monitoring for Jenkins"

# Push and create PR
git push origin feature/add-monitoring
# Create PR: feature/add-monitoring → develop
```

### 2. Release Workflow

```bash
# Create release branch
git checkout develop
git pull origin develop
git checkout -b release/v1.1.0

# Make final adjustments, update version
git add .
git commit -m "Prepare release v1.1.0"

# Push release branch
git push origin release/v1.1.0

# Create PRs:
# 1. release/v1.1.0 → master
# 2. release/v1.1.0 → develop (for any release fixes)
```

### 3. Hotfix Workflow

```bash
# Create hotfix from master
git checkout master
git pull origin master
git checkout -b hotfix/security-patch

# Make critical fix
git add .
git commit -m "Fix security vulnerability in Jenkins config"

# Push and create PRs
git push origin hotfix/security-patch
# Create PRs:
# 1. hotfix/security-patch → master
# 2. hotfix/security-patch → develop
```

## Merging Strategies

### 1. Feature to Develop
- **Strategy**: Squash and Merge
- **Reason**: Keeps develop history clean
- **PR Requirements**:
  - Code review approval
  - All checks pass
  - Up-to-date with develop

### 2. Release to Master
- **Strategy**: Create a Merge Commit
- **Reason**: Preserves release history
- **PR Requirements**:
  - Comprehensive testing completed
  - Documentation updated
  - Version tagged after merge

### 3. Hotfix to Master/Develop
- **Strategy**: Create a Merge Commit
- **Reason**: Maintains traceability of emergency fixes
- **PR Requirements**:
  - Critical fix validation
  - Immediate review and approval

### 4. Develop to Release
- **Strategy**: Create a Merge Commit
- **Reason**: Preserves feature history in release

## Environment Mapping

### Production Environment
- **Branch**: `master`
- **Deployment**: Automatic on merge to master
- **Terraform Workspace**: `production`
- **Validation**: Full test suite + manual approval

### Staging Environment
- **Branch**: `develop`
- **Deployment**: Automatic on merge to develop
- **Terraform Workspace**: `staging`
- **Validation**: Automated tests

### Development Environment
- **Branch**: `feature/*`
- **Deployment**: Manual/on-demand
- **Terraform Workspace**: `dev-[feature-name]`
- **Validation**: Basic syntax and format checks

## Commit Message Convention

Follow **Conventional Commits** format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples
```
feat(security): add AWS WAF for Jenkins
fix(iam): correct SSM permissions for EC2 role
docs(readme): update deployment instructions
chore(terraform): upgrade AWS provider to v5.1
```

## Pull Request Template

Create `.github/pull_request_template.md`:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change (fix or feature that causes existing functionality to change)
- [ ] Documentation update

## Testing
- [ ] Terraform validate passes
- [ ] Terraform plan reviewed
- [ ] Changes tested in development environment
- [ ] Security scan completed (if applicable)

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated (if needed)
- [ ] No sensitive data committed

## Terraform Changes
```
terraform plan output or summary of infrastructure changes
```

## Notes
Any additional context or considerations
```

## Release Process

### 1. Pre-Release Checklist
- [ ] All features merged to develop
- [ ] Terraform validate passes
- [ ] Security scan completed
- [ ] Documentation updated
- [ ] Version number updated

### 2. Release Steps
1. Create release branch from develop
2. Final testing and bug fixes
3. Update CHANGELOG.md
4. Create PR to master
5. Get approvals and merge
6. Tag the release
7. Merge release branch back to develop
8. Deploy to production

### 3. Post-Release
- [ ] Verify production deployment
- [ ] Monitor system health
- [ ] Clean up release branch
- [ ] Update project board/issues

## Emergency Procedures

### Critical Production Issue
1. Create hotfix branch from master immediately
2. Implement minimal fix
3. Test fix thoroughly
4. Create emergency PR with detailed explanation
5. Get expedited review and approval
6. Merge and deploy immediately
7. Follow up with proper post-mortem

### Rollback Procedure
1. Identify last known good commit
2. Create hotfix branch
3. Revert problematic changes
4. Follow emergency deployment process
5. Investigate root cause

## Best Practices

### Branch Naming
- Use descriptive names
- Include issue/ticket numbers when applicable
- Use lowercase with hyphens
- Examples: `feature/jenkins-backup`, `hotfix/security-cve-2023-001`

### Commit Practices
- Make atomic commits (one logical change per commit)
- Write clear, descriptive commit messages
- Reference issues/tickets in commits
- Avoid committing sensitive data

### Review Guidelines
- Review infrastructure changes carefully
- Validate Terraform plans
- Check for security implications
- Ensure documentation is updated
- Test changes in non-production environment first

## Tools and Automation

### Required Status Checks
- Terraform Format Check
- Terraform Validate
- Security Scan (Checkov/TFSec)
- Documentation Check

### Automated Workflows
- PR validation
- Automatic formatting
- Security scanning
- Deployment to staging/production

This branching strategy ensures safe, traceable, and efficient management of infrastructure changes while maintaining high availability and security standards.
