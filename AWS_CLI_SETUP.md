# AWS CLI Configuration Guide

## Quick Setup

### Option 1: Interactive Configuration (Recommended)

Run this in PowerShell:
```powershell
.\configure-aws.ps1
```

The script will prompt you for:
- AWS Access Key ID
- AWS Secret Access Key  
- Region (default: us-east-2)
- Output format (default: json)

### Option 2: Manual Configuration

Run this command:
```powershell
aws configure
```

Then enter:
1. **AWS Access Key ID**: Your access key
2. **AWS Secret Access Key**: Your secret key
3. **Default region name**: `us-east-2`
4. **Default output format**: `json` (or just press Enter)

### Option 3: Environment Variables (Temporary)

If you have temporary credentials:
```powershell
$env:AWS_ACCESS_KEY_ID="your-access-key-id"
$env:AWS_SECRET_ACCESS_KEY="your-secret-access-key"
$env:AWS_DEFAULT_REGION="us-east-2"
```

## Getting AWS Credentials

1. Go to **AWS Console** → **IAM** → **Users**
2. Click on your user (or create a new one)
3. Go to **Security Credentials** tab
4. Click **Create access key**
5. Choose **Command Line Interface (CLI)**
6. Copy the **Access Key ID** and **Secret Access Key**

⚠️ **Important**: Save your secret access key immediately - you won't be able to see it again!

## Verify Configuration

Test your configuration:
```powershell
aws sts get-caller-identity
```

This should show your AWS account ID and user ARN.

## After Configuration

Once configured, you can:
- Get EC2 instance IP: `aws ec2 describe-instances --instance-ids i-05648cb8983298e64 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region us-east-2`
- Test DNS: Use the `test-dns.ps1` script
- Run Terraform commands locally

