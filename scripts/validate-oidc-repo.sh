#!/bin/bash

# GitHub Actions OIDC Repository Name Validator
# This script checks if the trust policy matches the actual repository name

set -e

echo "================================"
echo "OIDC Repository Name Validator"
echo "================================"
echo

# Get repository info
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository"
    exit 1
fi

REMOTE_URL=$(git remote get-url origin)
REPO_NAME=$(echo "$REMOTE_URL" | sed -E 's|.*/([^/]+)/([^/]+)\.git|\1/\2|')

echo "📍 Repository Check"
echo "----------------------------"
echo "ℹ Remote URL: $REMOTE_URL"
echo "ℹ Repository: $REPO_NAME"
echo

# Get AWS account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")

if [ "$ACCOUNT_ID" = "unknown" ]; then
    echo "❌ Cannot get AWS account ID. Make sure AWS CLI is configured."
    exit 1
fi

echo "🔍 Trust Policy Check"
echo "----------------------------"

# Get the current trust policy
TRUST_POLICY=$(aws iam get-role --role-name GitHubActionsRole-FilmPro-Infra --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ Cannot find GitHubActionsRole-FilmPro-Infra role"
    exit 1
fi

# Extract the repository pattern from trust policy
TRUST_REPO=$(echo "$TRUST_POLICY" | jq -r '.Statement[0].Condition.StringLike."token.actions.githubusercontent.com:sub"' | sed 's/repo:\(.*\):\*/\1/')

echo "ℹ Trust Policy Repository: $TRUST_REPO"
echo "ℹ Actual Repository: $REPO_NAME"
echo

if [ "$TRUST_REPO" = "$REPO_NAME" ]; then
    echo "✅ Repository names match!"
    echo "ℹ OIDC authentication should work correctly"
else
    echo "❌ Repository name mismatch!"
    echo "🔧 The trust policy needs to be updated"
    echo
    echo "Fix command:"
    echo "============"
    echo "cat > trust-policy-fix.json << EOF"
    echo "{"
    echo "  \"Version\": \"2012-10-17\","
    echo "  \"Statement\": ["
    echo "    {"
    echo "      \"Effect\": \"Allow\","
    echo "      \"Principal\": {"
    echo "        \"Federated\": \"arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com\""
    echo "      },"
    echo "      \"Action\": \"sts:AssumeRoleWithWebIdentity\","
    echo "      \"Condition\": {"
    echo "        \"StringEquals\": {"
    echo "          \"token.actions.githubusercontent.com:aud\": \"sts.amazonaws.com\""
    echo "        },"
    echo "        \"StringLike\": {"
    echo "          \"token.actions.githubusercontent.com:sub\": \"repo:$REPO_NAME:*\""
    echo "        }"
    echo "      }"
    echo "    }"
    echo "  ]"
    echo "}"
    echo "EOF"
    echo
    echo "aws iam update-assume-role-policy --role-name GitHubActionsRole-FilmPro-Infra --policy-document file://trust-policy-fix.json"
    echo "rm trust-policy-fix.json"
    echo
fi

echo "🔄 GitHub Actions Status"
echo "----------------------------"
echo "ℹ Check your workflow runs at:"
echo "  https://github.com/$REPO_NAME/actions"
echo

echo "✅ Validation Complete"
echo "================================"
