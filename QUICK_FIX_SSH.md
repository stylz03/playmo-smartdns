# Quick Fix: Enable SSH Access via AWS Console

## The Problem
Your security group only allows SSH from IP `102.32.16.36/32`, which blocks AWS Instance Connect/CloudShell.

## Quick Fix (2 minutes)

### Step 1: Open AWS Console
1. Go to: https://console.aws.amazon.com/ec2/
2. Make sure you're in region: **us-east-2 (Ohio)**

### Step 2: Find Security Group
1. Click **"Security Groups"** in the left sidebar
2. Find: `playmo-smartdns-dns-only-sg`
3. Click on it

### Step 3: Edit Inbound Rules
1. Click **"Edit inbound rules"** button
2. Find the SSH rule (Type: SSH, Port: 22)
3. Click **"Add rule"** button
4. Configure the new rule:
   - **Type**: SSH
   - **Port**: 22
   - **Source**: Select **"Anywhere-IPv4"** (this sets it to `0.0.0.0/0`)
   - **Description**: "Allow SSH from AWS Instance Connect"
5. Click **"Save rules"**

### Step 4: Try Connecting Again
1. Go back to EC2 → Instances
2. Select your instance: `playmo-smartdns-dns-only-ec2`
3. Click **"Connect"**
4. Try **"EC2 Instance Connect"** or **"CloudShell"** again

## Alternative: Update via Terraform

If you prefer to use Terraform, I've created `terraform/fix-ssh.tf`. You can apply it:

```bash
cd terraform
terraform apply
```

This will add an additional SSH rule allowing access from anywhere.

## Security Note
⚠️ **After troubleshooting, restrict SSH access back to your specific IP for better security.**

