# CI/CD OIDC Trust Policy Fix

Fixed the trust policy repository name case-sensitivity issue that was preventing GitHub Actions from assuming the AWS IAM role.

**Issue**: Trust policy was configured for `FilmPro-Infra` but repository is `filmpro-infra`
**Fix**: Updated trust policy to match actual repository name (case-sensitive)

Date: 2024-09-16
