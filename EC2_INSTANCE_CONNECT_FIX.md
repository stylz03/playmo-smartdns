# Fix EC2 Instance Connect Connection

## The Problem
EC2 Instance Connect is failing because:
1. **Security Group**: Only allows SSH (port 22) from `102.32.16.36/32`
2. **EC2 Instance Connect** uses AWS's infrastructure which has different IP addresses
3. Even though you don't need a key pair, port 22 must be accessible

## Solution: Update Security Group

### Option 1: Allow SSH from Anywhere (Quick Fix)
This will allow EC2 Instance Connect to work immediately.

**Via AWS Console:**
1. Go to: https://console.aws.amazon.com/ec2/v2/home?region=us-east-2#SecurityGroups:
2. Find: `playmo-smartdns-dns-only-sg`
3. Click **"Edit inbound rules"**
4. Find the SSH rule (port 22)
5. Click **"Add rule"** (or edit existing)
6. Set:
   - **Type**: SSH
   - **Port**: 22
   - **Source**: **Anywhere-IPv4** (`0.0.0.0/0`)
   - **Description**: "Allow EC2 Instance Connect"
7. Click **"Save rules"**

### Option 2: Allow from AWS Instance Connect IP Ranges (More Secure)
EC2 Instance Connect uses specific AWS IP ranges. However, the easiest approach is to temporarily allow from anywhere, then restrict later.

### Option 3: Use Terraform
I've created `terraform/fix-ssh.tf` which adds a rule allowing SSH from anywhere.

```bash
cd terraform
terraform apply
```

## After Fixing Security Group

1. **Wait 30 seconds** for the security group change to propagate
2. **Try EC2 Instance Connect again**:
   - Go to EC2 → Instances
   - Select your instance
   - Click "Connect"
   - Choose "EC2 Instance Connect" tab
   - Click "Connect"

## Verify IAM Permissions

EC2 Instance Connect requires these IAM permissions:
- `ec2-instance-connect:SendSSHPublicKey`

If you're using the root account or an admin user, you should have these permissions. If not, you may need to add them.

## Alternative: Use Session Manager

If EC2 Instance Connect still doesn't work, try **Session Manager**:
1. Requires SSM agent (usually pre-installed on Ubuntu)
2. No SSH/port 22 needed
3. Uses IAM permissions instead
4. Go to "Connect" → "Session Manager" tab

## Check Instance Status

Make sure the instance is:
- ✅ **Running** (not stopped/terminated)
- ✅ **Status checks**: 2/2 passed
- ✅ **Security group**: Has SSH rule allowing your connection

