# Add IAM Permissions to GitHub Actions Role

This Terraform configuration adds the necessary IAM permissions to the `playmo-terraform-deploy` role so it can create IAM roles and policies for the SmartDNS Lambda function.

## Prerequisites

- AWS CLI configured with admin credentials (or credentials with IAM management permissions)
- Terraform installed

## Usage

1. **Configure AWS credentials** (if not already configured):
   ```bash
   aws configure
   ```

2. **Initialize Terraform**:
   ```bash
   cd terraform-iam-permissions
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Apply the changes**:
   ```bash
   terraform apply
   ```

This will:
- Create a new IAM policy with the required permissions
- Attach the policy to the `playmo-terraform-deploy` role

## What Permissions Are Added?

The policy grants the following permissions (scoped to SmartDNS resources):
- `iam:CreateRole` - Create Lambda execution roles
- `iam:CreatePolicy` - Create IAM policies
- `iam:AttachRolePolicy` / `iam:DetachRolePolicy` - Attach/detach policies
- `iam:PassRole` - Pass roles to Lambda service
- Various read/list permissions for IAM resources

All permissions are scoped to resources matching `playmo-smartdns-dns-only-*` patterns for security.

## Cleanup

To remove the permissions:
```bash
terraform destroy
```


