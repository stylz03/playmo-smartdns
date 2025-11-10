# Quick Start: Add IAM Permissions

## What You Need

- AWS account access with IAM admin permissions
- One of the following:
  - **Terraform** installed (for Option 1)
  - **AWS CLI** installed (for Option 2)
  - **AWS Console** access (for Option 3)

## Option 1: Using Terraform (Recommended)

```bash
cd terraform-iam-permissions
terraform init
terraform plan    # Review what will be created
terraform apply   # Apply the changes
```

## Option 2: Using AWS CLI

If you're on Linux/Mac:
```bash
cd terraform-iam-permissions
chmod +x add-permissions.sh
./add-permissions.sh
```

If you're on Windows (PowerShell):
```powershell
# You'll need to manually run the AWS CLI commands
# See the script file for the exact commands
```

## Option 3: Using AWS Console (Manual)

1. Go to AWS Console → IAM → Policies → Create Policy
2. Use JSON tab and paste the policy from `terraform-iam-permissions/main.tf` (the policy document)
3. Name it: `playmo-terraform-iam-permissions`
4. Create the policy
5. Go to IAM → Roles → `playmo-terraform-deploy`
6. Click "Add permissions" → "Attach policies"
7. Search for and select `playmo-terraform-iam-permissions`
8. Attach the policy

## Verify

After adding permissions, your GitHub Actions workflow should be able to create IAM roles and policies for the Lambda function.

## Need Help?

The Terraform script is the safest option as it's idempotent and can be easily removed with `terraform destroy`.


