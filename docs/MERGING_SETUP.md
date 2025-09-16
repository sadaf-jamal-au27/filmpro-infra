# Enabling Merging Strategies - Setup Guide

This guide explains how to enable and configure the merging strategies for the FilmPro Infrastructure project.

## GitHub Repository Settings Configuration

### 1. Branch Protection Rules

You need to configure branch protection rules in your GitHub repository. These settings cannot be automated through code and must be set up manually in the GitHub web interface.

#### For Master Branch (Production)

1. Go to your repository: https://github.com/sadaf-jamal-au27/filmpro-infra
2. Navigate to **Settings** → **Branches**
3. Click **Add rule** or edit existing rule for `master`
4. Configure the following settings:

```
Branch name pattern: master

☑️ Restrict pushes that create files to this branch
☑️ Require a pull request before merging
   ☑️ Require approvals: 1
   ☑️ Dismiss stale pull request approvals when new commits are pushed
   ☑️ Require review from code owners (if CODEOWNERS file exists)
   ☑️ Restrict dismissals to specific people/teams

☑️ Require status checks to pass before merging
   ☑️ Require branches to be up to date before merging
   Status checks to require:
   - Terraform Validation and Security
   - terraform-plan (for PRs)

☑️ Require conversation resolution before merging
☑️ Require linear history
☑️ Require deployments to succeed before merging
   - production environment

☑️ Restrict pushes that create files to this branch
☑️ Do not allow bypassing the above settings
☑️ Restrict pushes that create files to this branch
```

#### For Develop Branch (Staging)

1. Add another rule for `develop` branch:

```
Branch name pattern: develop

☑️ Require a pull request before merging
   ☑️ Require approvals: 1
   ☑️ Dismiss stale pull request approvals when new commits are pushed

☑️ Require status checks to pass before merging
   ☑️ Require branches to be up to date before merging
   Status checks to require:
   - Terraform Validation and Security

☑️ Require conversation resolution before merging
☑️ Allow force pushes (for administrators only)
```

### 2. Repository Settings

#### General Settings
1. Go to **Settings** → **General**
2. Configure merge button options:

```
☑️ Allow merge commits
☑️ Allow squash merging
☑️ Allow rebase merging

Default to: "Create a merge commit" for releases
Default to: "Squash and merge" for features
```

#### Environment Protection Rules
1. Go to **Settings** → **Environments**
2. Create environments:

**Staging Environment:**
```
Name: staging
Protection rules:
☑️ Required reviewers: 0 (automatic deployment)
☑️ Wait timer: 0 minutes
☑️ Prevent administrators from bypassing configured protection rules: No
```

**Production Environment:**
```
Name: production
Protection rules:
☑️ Required reviewers: 1 (you or team leads)
☑️ Wait timer: 5 minutes (cooling off period)
☑️ Prevent administrators from bypassing configured protection rules: Yes
```

### 3. Secrets Configuration

Add the following secrets in **Settings** → **Secrets and variables** → **Actions**:

```
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
```

## Automated Setup Script

I'll create a script that helps you verify and configure what can be automated.

## Manual Configuration Steps

### Step 1: Create CODEOWNERS File (Optional)
This file defines who needs to review specific parts of the code.

### Step 2: Configure Team Permissions
Set up teams and assign appropriate permissions:
- **Maintainers**: Can approve PRs, bypass some restrictions
- **Contributors**: Can create PRs, cannot merge to protected branches
- **Viewers**: Read-only access

### Step 3: Set Up Notifications
Configure notifications for:
- Failed deployments
- Security alerts
- PR reviews required

## Workflow Examples

### Feature Development with Enforced Reviews

```bash
# 1. Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/add-monitoring

# 2. Make changes
echo "# Add CloudWatch monitoring" >> monitoring.tf
git add monitoring.tf
git commit -m "feat(monitoring): add CloudWatch for Jenkins instance"

# 3. Push feature branch
git push origin feature/add-monitoring

# 4. Create Pull Request (via GitHub web interface or CLI)
gh pr create --base develop --title "Add CloudWatch monitoring" --body "Adds comprehensive monitoring for Jenkins instance"

# 5. Wait for:
#    - Automated checks to pass
#    - Code review and approval
#    - Squash and merge by reviewer

# 6. Clean up after merge
git checkout develop
git pull origin develop
git branch -d feature/add-monitoring
```

### Release Process with Protection

```bash
# 1. Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/v1.1.0

# 2. Prepare release (update versions, docs)
echo "## [1.1.0] - $(date +%Y-%m-%d)" >> CHANGELOG.md
git add CHANGELOG.md
git commit -m "chore: prepare release v1.1.0"
git push origin release/v1.1.0

# 3. Create PR to master
gh pr create --base master --title "Release v1.1.0" --body "Release containing monitoring improvements"

# 4. Process will enforce:
#    - All status checks pass
#    - Required approvals obtained
#    - Linear history maintained
#    - Production deployment approval
```

## Merge Strategy Configuration

### Automatic Strategy Selection

The system will automatically choose merge strategies based on the branch:

- **feature → develop**: Squash and merge (keeps history clean)
- **release → master**: Create merge commit (preserves release structure)
- **hotfix → master/develop**: Create merge commit (maintains traceability)

### Manual Override (When Needed)

For special cases, maintainers can choose different strategies:

1. **Squash and Merge**: Combines all commits into one
   - Use for: Feature branches with many small commits
   - Result: Clean, linear history

2. **Create Merge Commit**: Preserves branch structure
   - Use for: Releases, hotfixes, important feature sets
   - Result: Full commit history preserved

3. **Rebase and Merge**: Replays commits without merge commit
   - Use for: Small, clean commits that don't need squashing
   - Result: Linear history with individual commits

## Verification Commands

After setting up, verify the configuration:

```bash
# Check branch protection
gh api repos/sadaf-jamal-au27/filmpro-infra/branches/master/protection

# List required status checks
gh api repos/sadaf-jamal-au27/filmpro-infra/branches/master/protection/required_status_checks

# Check environments
gh api repos/sadaf-jamal-au27/filmpro-infra/environments
```

## Troubleshooting

### Common Issues

1. **Status checks not appearing**
   - Ensure the workflow has run at least once
   - Check that workflow names match exactly

2. **Cannot merge despite passing checks**
   - Verify all required reviewers have approved
   - Check that branch is up to date with base

3. **Environment deployment hanging**
   - Check if environment requires manual approval
   - Verify AWS credentials are correctly configured

### Emergency Procedures

If you need to bypass protections for critical fixes:

1. **Temporary rule disabling** (Admin only):
   - Go to Settings → Branches
   - Temporarily disable specific rules
   - Apply hotfix
   - Re-enable rules immediately

2. **Admin override**:
   - Use administrator privileges to merge
   - Document the override reason
   - Follow up with proper review post-merge

## Best Practices

1. **Never disable protections permanently**
2. **Always document emergency overrides**
3. **Regularly review and update protection rules**
4. **Train team members on the workflow**
5. **Monitor compliance and adjust rules as needed**

This configuration ensures that your infrastructure changes go through proper review, testing, and approval processes while maintaining flexibility for different types of changes.
