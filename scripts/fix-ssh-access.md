# Fix SSH Access to EC2 Instance

## Problem
The security group only allows SSH from a specific IP (`102.32.16.36/32`), which blocks AWS Instance Connect/CloudShell.

## Solution Options

### Option 1: Allow SSH from AWS Instance Connect (Recommended)
AWS Instance Connect uses AWS's IP ranges. We need to add a rule that allows connections from AWS's Instance Connect service.

**Via AWS Console:**
1. Go to EC2 → Security Groups
2. Find the security group: `playmo-smartdns-dns-only-sg`
3. Click "Edit inbound rules"
4. Add a new rule:
   - Type: SSH
   - Source: Select "My IP" or "Anywhere-IPv4" (0.0.0.0/0) temporarily
   - Description: "Allow SSH from AWS Instance Connect"
5. Save rules

**Via Terraform (Update and Apply):**
Update `terraform/variables.tf` to allow SSH from anywhere temporarily, or add a separate rule for Instance Connect.

### Option 2: Temporarily Allow SSH from Anywhere (Quick Fix)
This is less secure but will work immediately.

**Via AWS Console:**
1. Go to EC2 → Security Groups → `playmo-smartdns-dns-only-sg`
2. Edit inbound rules
3. Find the SSH rule (port 22)
4. Change Source from `102.32.16.36/32` to `0.0.0.0/0`
5. Save

**Via Terraform:**
Update `terraform/variables.tf`:
```hcl
variable "ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"  # Temporarily allow from anywhere
}
```
Then run `terraform apply`.

### Option 3: Add Your Current IP
If you know your current public IP, add it to the security group.

### Option 4: Use AWS Systems Manager Session Manager (No SSH needed)
If the instance has SSM agent installed, you can use Session Manager instead of SSH.

## Check Key Pair
Also verify the instance has a key pair configured:
1. Go to EC2 → Instances
2. Select your instance
3. Check "Key pair name" in the details
4. If it says "None", you'll need to either:
   - Stop the instance, attach a key pair, and restart
   - Use Session Manager instead

## After Fixing
Once SSH access is fixed, you can:
1. Connect via AWS Instance Connect
2. Check API service status
3. Manually fix any issues

