# GitHub and AWS OIDC Setup Guide

This guide explains how to set up secure AWS authentication for your CI/CD pipeline using OIDC (OpenID Connect) instead of long-lived access keys.

## Prerequisites
- AWS Account with admin access
- GitHub repository with appropriate permissions
- AWS CLI installed and configured

## Step 1: Create AWS OIDC Identity Provider

1. **In AWS Console, go to IAM → Identity providers**
2. **Click "Add provider"**
3. **Configure the provider:**
   - Provider type: `OpenID Connect`
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
4. **Click "Add provider"**

### Or use AWS CLI:
```bash
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## Step 2: Create IAM Role for GitHub Actions

1. **Create trust policy file** (`github-actions-trust-policy.json`):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::YOUR-ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:YOUR-USERNAME/FilmPro-Infra:*"
                }
            }
        }
    ]
}
```

2. **Replace placeholders:**
   - `YOUR-ACCOUNT-ID`: Your AWS account ID
   - `YOUR-USERNAME`: Your GitHub username

3. **Create the role:**
```bash
aws iam create-role \
    --role-name GitHubActionsRole \
    --assume-role-policy-document file://github-actions-trust-policy.json
```

4. **Attach necessary policies:**
```bash
# For EC2 and related services
aws iam attach-role-policy \
    --role-name GitHubActionsRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# For IAM operations (needed for instance profiles)
aws iam attach-role-policy \
    --role-name GitHubActionsRole \
    --policy-arn arn:aws:iam::aws:policy/IAMFullAccess

# For Systems Manager (SSM)
aws iam attach-role-policy \
    --role-name GitHubActionsRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess
```

## Step 3: Configure GitHub Repository Secrets

1. **Go to your GitHub repository**
2. **Navigate to Settings → Secrets and variables → Actions**
3. **Add repository secret:**
   - Name: `AWS_ROLE_ARN`
   - Value: `arn:aws:iam::YOUR-ACCOUNT-ID:role/GitHubActionsRole`

## Step 4: Set Up GitHub Environments

1. **Go to Settings → Environments in your GitHub repository**
2. **Create "staging" environment:**
   - Click "New environment"
   - Name: `staging`
   - Add protection rules (optional):
     - Required reviewers: Add team members
     - Wait timer: 0 minutes
     - Environment secrets: None needed (uses repository secrets)

3. **Create "production" environment:**
   - Click "New environment"
   - Name: `production`
   - Add protection rules (recommended):
     - Required reviewers: Add senior team members
     - Wait timer: 5 minutes (gives time to cancel if needed)
     - Restrict deployments to protected branches: `master`

## Step 5: Configure Branch Protection Rules

1. **Go to Settings → Branches in your GitHub repository**
2. **Add rule for `master` branch:**
   - Branch name pattern: `master`
   - Require a pull request before merging: ✅
   - Require approvals: 2
   - Dismiss stale PR approvals when new commits are pushed: ✅
   - Require review from code owners: ✅
   - Require status checks to pass before merging: ✅
     - Add status check: `Terraform Validation and Security`
   - Require branches to be up to date before merging: ✅
   - Require signed commits: ✅ (recommended)
   - Include administrators: ✅

3. **Add rule for `develop` branch:**
   - Branch name pattern: `develop`
   - Require a pull request before merging: ✅
   - Require approvals: 1
   - Require status checks to pass before merging: ✅
     - Add status check: `Terraform Validation and Security`
   - Require branches to be up to date before merging: ✅

## Step 6: Test the Setup

1. **Create a feature branch:**
```bash
git checkout -b feature/test-cicd
echo "# Test change" >> README.md
git add README.md
git commit -m "test: verify CI/CD pipeline"
git push origin feature/test-cicd
```

2. **Create a Pull Request:**
   - Open PR from `feature/test-cicd` to `develop`
   - Verify that the CI/CD pipeline runs
   - Check that terraform validation passes
   - Verify that the plan is commented on the PR

3. **Merge to develop:**
   - Merge the PR to trigger staging deployment
   - Verify that staging deployment runs successfully

4. **Merge to master:**
   - Create PR from `develop` to `master`
   - Merge to trigger production deployment
   - Verify that production deployment runs with approval

## Troubleshooting

### Common Issues:

1. **"Error: Could not assume role"**
   - Check that the AWS_ROLE_ARN secret is correct
   - Verify the trust policy allows your repository
   - Ensure the OIDC provider is properly configured

2. **"Environment protection rules"**
   - Check that environments are properly configured
   - Verify that required reviewers are available
   - Ensure branch protection rules are not blocking

3. **"Status checks required"**
   - Ensure the status check names match exactly
   - Verify that the checks are enabled in branch protection

### Useful Commands:

```bash
# Check AWS role
aws sts get-caller-identity

# Validate trust policy
aws iam get-role --role-name GitHubActionsRole

# Test OIDC provider
aws iam list-open-id-connect-providers
```

## Security Best Practices

1. **Use least privilege principle:** Only grant necessary permissions to the GitHub Actions role
2. **Regular audits:** Review role permissions and access logs regularly
3. **Environment separation:** Use different AWS accounts for staging/production
4. **Monitoring:** Set up CloudTrail to monitor API calls from GitHub Actions
5. **Secrets rotation:** While OIDC tokens are short-lived, review and update trust policies regularly

## Next Steps

1. Set up different AWS accounts for staging and production
2. Implement Terraform state backend (S3 + DynamoDB)
3. Add infrastructure drift detection
4. Set up monitoring and alerting for deployments
5. Implement automated testing for infrastructure changes
