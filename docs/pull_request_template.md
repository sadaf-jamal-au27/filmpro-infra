## Description
Brief description of the infrastructure changes being made.

## Type of Change
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🔧 Configuration change
- [ ] 🔐 Security improvement

## Infrastructure Changes
<!-- Describe what AWS resources are being created, modified, or deleted -->

### Resources Affected
- [ ] EC2 Instances
- [ ] Security Groups
- [ ] IAM Roles/Policies
- [ ] Networking (VPC, Subnets, etc.)
- [ ] Storage (EBS, S3, etc.)
- [ ] Other: _______________

## Testing Checklist
- [ ] `terraform fmt` - Code formatting is correct
- [ ] `terraform validate` - Configuration is valid
- [ ] `terraform plan` - Plan reviewed and approved
- [ ] Security scan completed (Checkov/TFSec)
- [ ] Changes tested in development environment
- [ ] No sensitive data committed

## Terraform Plan Output
```
Paste the relevant parts of terraform plan output here
```

## Security Considerations
<!-- Describe any security implications of these changes -->
- [ ] No new security groups with overly permissive rules
- [ ] IAM policies follow least privilege principle
- [ ] No hardcoded secrets or sensitive data
- [ ] Security groups properly configured

## Cost Impact
<!-- Estimate the cost impact of these changes -->
- [ ] No significant cost increase
- [ ] Minor cost increase (< $10/month)
- [ ] Moderate cost increase ($10-100/month)
- [ ] Major cost increase (> $100/month) - Requires approval

## Documentation
- [ ] README.md updated (if applicable)
- [ ] CHANGELOG.md updated
- [ ] Comments added to complex configurations
- [ ] Architecture diagrams updated (if applicable)

## Deployment Plan
<!-- Describe how this will be deployed -->
- [ ] Can be deployed during business hours
- [ ] Requires maintenance window
- [ ] Zero-downtime deployment
- [ ] Requires manual intervention

## Rollback Plan
<!-- Describe how to rollback if something goes wrong -->

## Additional Notes
<!-- Any additional context, screenshots, or information -->

---

### Reviewer Checklist
- [ ] Code follows project conventions
- [ ] Infrastructure changes are necessary and appropriate
- [ ] Security implications reviewed
- [ ] Cost impact acceptable
- [ ] Documentation is adequate
- [ ] Testing is sufficient
