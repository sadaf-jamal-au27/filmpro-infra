# Jenkins Infrastructure on AWS

This Terraform project creates a Jenkins server on AWS EC2 with secure access through AWS Systems Manager Session Manager.

## Project Structure

```
FilmPro-Infra/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── provider.tf             # Provider configuration
├── terraform.tfvars        # Variable values
├── scripts/
│   └── install_jenkins.sh  # Jenkins installation script
└── README.md               # This file
```

## Prerequisites

1. AWS CLI installed and configured with appropriate credentials
2. Terraform installed (version 1.0 or later)
3. AWS account with permissions to create EC2, IAM, and Security Group resources

## What This Creates

- EC2 instance (t3.small) running Ubuntu 20.04
- Security Group allowing inbound traffic on port 8080 (Jenkins)
- IAM Role and Instance Profile for EC2 with SSM permissions
- Automatic Jenkins installation via user data script

## Setup Instructions

### Step 1: Clone and Navigate
```bash
cd /Applications/CICD/DevopsInsider/FilmPro-Infra
```

### Step 2: Initialize Terraform
```bash
terraform init
```

### Step 3: Validate Configuration
```bash
terraform validate
```
This checks the syntax and configuration for errors.

### Step 4: Review the Configuration (Dry-Run)
```bash
terraform plan
```
This shows what resources will be created without actually creating them.

### Step 5: Deploy the Infrastructure
```bash
terraform apply
```
Type 'yes' when prompted to confirm the deployment.

### Step 6: Get Connection Information
After deployment, Terraform will output:
- Public IP of the Jenkins server
- Command to connect via Session Manager

## Accessing Jenkins

### Method 1: Web Interface
1. Wait 5-10 minutes for Jenkins to install and start
2. Open your browser and go to: `http://[PUBLIC_IP]:8080`
3. Get the initial admin password (see Session Manager section below)

### Method 2: Session Manager (Secure Shell Access)
Connect to your instance securely without SSH:
```bash
aws ssm start-session --target [INSTANCE_ID]
```
Replace [INSTANCE_ID] with the instance ID from Terraform output.

## Getting Jenkins Initial Password

1. Connect via Session Manager (command above)
2. Run this command to get the initial admin password:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Security Features

- No SSH access (port 22 is not exposed)
- Access through AWS Systems Manager Session Manager
- Minimal security group rules (only port 8080 for Jenkins)
- IAM role with least privilege principle

## Customization

### Change Instance Type
Edit `terraform.tfvars`:
```
instance_type = "t3.medium"  # or t2.small, t3.large, etc.
```

### Modify Installation Script
Edit `scripts/install_jenkins.sh` to add additional software or configurations.

## Validation and Testing

### Pre-Deployment Validation
Before deploying, always validate your configuration:

1. **Syntax Check**:
```bash
terraform validate
```

2. **Format Check**:
```bash
terraform fmt -check
```

3. **Dry-Run (Plan)**:
```bash
terraform plan
```
Review the output carefully to ensure only expected resources will be created.

4. **Security Scan** (Optional):
```bash
# Install checkov if not already installed
pip install checkov

# Run security scan
checkov -f main.tf
```

### Post-Deployment Validation
After deployment, verify everything is working:

1. **Check Terraform State**:
```bash
terraform show
```

2. **Verify Instance is Running**:
```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=myserver" --query 'Reservations[].Instances[].State.Name'
```

3. **Test Session Manager Connection**:
```bash
aws ssm start-session --target [INSTANCE_ID] --dry-run
```

4. **Check Jenkins Service Status** (via Session Manager):
```bash
# Connect first, then run:
sudo systemctl status jenkins
```

5. **Verify Jenkins Web Interface**:
Open browser to `http://[PUBLIC_IP]:8080` and check if Jenkins login page loads.

## Cleanup

To destroy all resources and avoid charges:
```bash
terraform destroy
```
Type 'yes' when prompted.

## Cost Considerations

- t3.small instance: ~$15-16/month if running 24/7
- EBS storage: ~$1-2/month for 8GB root volume
- Data transfer: Minimal for normal Jenkins usage

To minimize costs:
- Stop the instance when not in use
- Consider using smaller instance types for testing
- Use spot instances for non-production workloads

## Troubleshooting

### Jenkins Not Accessible
1. Check if the instance is running in AWS Console
2. Verify security group allows port 8080
3. Wait 10-15 minutes for initial setup to complete
4. Check user data logs: `sudo tail -f /var/log/cloud-init-output.log`

### Session Manager Connection Issues
1. Ensure AWS CLI is configured correctly
2. Verify the instance has the SSM agent running
3. Check IAM permissions for your AWS user

### Instance Creation Fails
1. Check if you have sufficient AWS permissions
2. Verify the instance type is available in your region
3. Ensure you're not hitting AWS service limits

## File Descriptions

- **main.tf**: Contains all AWS resources (EC2, Security Group, IAM)
- **variables.tf**: Defines input variables for the configuration
- **terraform.tfvars**: Sets values for the variables
- **outputs.tf**: Defines what information to display after deployment
- **provider.tf**: Configures the AWS provider
- **scripts/install_jenkins.sh**: Bash script that installs Jenkins and dependencies

## Support

For AWS-specific issues, refer to AWS documentation.
For Terraform issues, refer to Terraform documentation.
For Jenkins issues, refer to Jenkins documentation.
