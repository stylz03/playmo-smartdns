# Setup Instructions for Adding IAM Permissions

## Step 1: Configure AWS Credentials

You need AWS credentials with IAM admin permissions. Choose one of these methods:

### Method A: Using AWS Access Keys

1. Get your AWS Access Key ID and Secret Access Key from:
   - AWS Console → IAM → Your User → Security Credentials → Access Keys
   - Or ask your AWS administrator

2. Run this command and enter your credentials when prompted:
   ```powershell
   aws configure
   ```
   
   You'll be asked for:
   - AWS Access Key ID: [enter your key]
   - AWS Secret Access Key: [enter your secret]
   - Default region name: `us-east-2` (or press Enter)
   - Default output format: `json` (or press Enter)

### Method B: Using AWS SSO (if your organization uses it)

```powershell
aws configure sso
```

Follow the prompts to set up SSO.

### Method C: Using Temporary Credentials

If you have temporary credentials (from AWS Console or another source):
```powershell
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_SESSION_TOKEN="your-session-token"  # if using temporary credentials
```

## Step 2: Verify Your Credentials

Test that your credentials work:
```powershell
aws sts get-caller-identity
```

This should show your AWS account ID and user/role ARN.

## Step 3: Run the Script

Once credentials are configured, run:
```powershell
cd terraform-iam-permissions
.\add-permissions.ps1
```

## Troubleshooting

- **"Access Denied"**: Your credentials don't have IAM admin permissions. Contact your AWS administrator.
- **"Role not found"**: Make sure you're in the correct AWS account (843336589038).
- **"Policy already exists"**: That's okay! The script will use the existing policy.

## Alternative: Use AWS Console

If you prefer not to use AWS CLI, you can manually add the permissions through the AWS Console. See `QUICK_START.md` for instructions.

