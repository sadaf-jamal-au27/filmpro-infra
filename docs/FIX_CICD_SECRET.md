# 🔧 URGENT: Add GitHub Secret to Fix CI/CD

## ❌ Current Issue
Your GitHub Actions workflow is failing with:
```
Error: Credentials could not be loaded, please check your action inputs: Could not load credentials from any providers
```

## ✅ Solution: Add AWS_ROLE_ARN Secret

### Step 1: Go to GitHub Repository Settings
1. **Open your repository**: https://github.com/sadaf-jamal-au27/filmpro-infra
2. **Click "Settings"** (top navigation bar)
3. **Click "Secrets and variables"** (left sidebar)
4. **Click "Actions"**

### Step 2: Add the Secret
1. **Click "New repository secret"**
2. **Name**: `AWS_ROLE_ARN`
3. **Secret**: `arn:aws:iam::008099619893:role/GitHubActionsRole-FilmPro-Infra`
4. **Click "Add secret"**

### Step 3: Verify the Secret
After adding the secret, you should see:
- ✅ `AWS_ROLE_ARN` in your repository secrets list
- 🔒 Secret value hidden (shows as `***`)

## 🧪 Test the Fix

After adding the secret, test it by:

### Option 1: Create a Test PR
```bash
git checkout -b test/fix-cicd
echo "# Test CI/CD fix" >> README.md
git add README.md
git commit -m "test: verify CI/CD pipeline after adding AWS_ROLE_ARN secret"
git push origin test/fix-cicd
```
Then create a PR from `test/fix-cicd` to `develop`.

### Option 2: Push to Develop Branch
```bash
git checkout develop
git pull origin develop  # if develop exists
echo "# CI/CD test" >> README.md
git add README.md
git commit -m "test: verify staging deployment"
git push origin develop
```

## 🔍 Troubleshooting

If the secret is added correctly but you still see errors:

### Check 1: Secret Name is Exact
- Must be exactly: `AWS_ROLE_ARN` (case-sensitive)
- No extra spaces or characters

### Check 2: Secret Value is Correct
- Must be exactly: `arn:aws:iam::008099619893:role/GitHubActionsRole-FilmPro-Infra`
- No line breaks or extra characters

### Check 3: Environment Configuration
If you're deploying to staging/production, also ensure:
1. **Go to Settings → Environments**
2. **Create `staging` environment** (if deploying to develop branch)
3. **Create `production` environment** (if deploying to master branch)

## 🚀 Expected Results

After adding the secret correctly:

✅ **For Pull Requests**:
- Terraform validation runs ✓
- Security scan runs ✓
- Terraform plan is generated and commented on PR ✓

✅ **For Develop Branch**:
- Validation and planning run ✓
- Staging deployment executes ✓
- Jenkins infrastructure is deployed ✓

✅ **For Master Branch**:
- Production deployment runs ✓
- Automated release is created ✓

## 📞 Quick Help

**Direct Link to Add Secret**: 
https://github.com/sadaf-jamal-au27/filmpro-infra/settings/secrets/actions/new

**Secret Details**:
- **Name**: `AWS_ROLE_ARN`
- **Value**: `arn:aws:iam::008099619893:role/GitHubActionsRole-FilmPro-Infra`

---
**Once you add this secret, your CI/CD pipeline will be fully functional! 🎯**
