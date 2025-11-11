# Terraform Update Strategy - Preventing Unnecessary Instance Recreation

## The Problem

When Terraform applies changes, it may recreate the EC2 instance, which:
- Changes the instance ID
- May temporarily disassociate the Elastic IP
- Requires re-running user_data (slow)
- Loses any manual configuration changes

## Why This Happens

Terraform recreates resources when:
1. **Force replacement attributes change**: AMI, instance type, subnet, etc.
2. **user_data changes**: Any change to user_data triggers recreation
3. **Resource dependencies change**: Security group, key pair, etc.

## Current Configuration

### Elastic IP
- ✅ Separate resource (not destroyed with instance)
- ✅ Lifecycle rules to prevent unnecessary changes
- ✅ Should persist across instance recreations

### EC2 Instance
- ✅ Lifecycle rules to prevent unnecessary recreation
- ✅ `create_before_destroy = true` for smooth transitions
- ⚠️ `ignore_changes` for user_data (commented out - can enable if needed)

## Best Practices for Updates

### Option 1: Update Without Recreation (Recommended)

**For configuration changes that don't require instance recreation:**

1. **Update user_data manually on running instance:**
   ```bash
   # SSH into instance
   # Make changes directly
   # Restart services
   ```

2. **Use `terraform apply -refresh-only`:**
   ```bash
   terraform apply -refresh-only
   # Updates state without making changes
   ```

3. **Use `terraform apply -target`:**
   ```bash
   # Only update specific resources
   terraform apply -target=aws_security_group.smartdns_sg
   ```

### Option 2: Controlled Recreation

**When instance recreation is necessary:**

1. **Check what will be recreated:**
   ```bash
   terraform plan
   # Look for "forces replacement" warnings
   ```

2. **Use `terraform apply -replace`:**
   ```bash
   # Only replace specific resource
   terraform apply -replace=aws_instance.smartdns
   ```

3. **The Elastic IP should persist:**
   - EIP is separate resource
   - Association will be recreated automatically
   - IP address stays the same

## Preventing Recreation

### 1. Ignore user_data Changes

If you want to update user_data without recreating:

```hcl
lifecycle {
  ignore_changes = [user_data]
}
```

**Warning**: This means Terraform won't update user_data automatically. You'll need to manually update or recreate when needed.

### 2. Use Data Sources for Existing Resources

If resources already exist, use data sources instead of resources:

```hcl
# Instead of creating new EIP, use existing
data "aws_eip" "existing" {
  public_ip = "3.151.46.11"  # Your current IP
}
```

### 3. Import Existing Resources

If resources exist but aren't in Terraform state:

```bash
terraform import aws_eip.smartdns eipalloc-xxxxx
terraform import aws_instance.smartdns i-xxxxx
```

## Current Elastic IP

**To find your current Elastic IP:**

```bash
# From GitHub Actions output
terraform output ec2_public_ip

# Or from AWS Console
# EC2 → Elastic IPs → Find your EIP
```

**The Elastic IP should be:**
- Same IP address (static)
- Persists across instance recreations
- Automatically re-associated when instance is recreated

## Recommendations

### For Regular Updates:

1. **Use `terraform plan` first** - See what will change
2. **Avoid changing force-replacement attributes** - AMI, instance type, etc.
3. **Update user_data manually** - If possible, update on running instance
4. **Use targeted applies** - Only update what's needed

### For Major Updates:

1. **Plan the update** - Know what will be recreated
2. **Backup important data** - If any manual configs exist
3. **Apply during maintenance window** - Instance will be down briefly
4. **Verify Elastic IP** - Should remain the same

## Checking Current IP

After deployment, check the new IP:

```bash
# From GitHub Actions
terraform output ec2_public_ip

# Or from AWS Console
# EC2 → Instances → Your instance → Public IPv4 address
```

## If IP Changed

If the Elastic IP did change:

1. **Check if old EIP still exists:**
   ```bash
   aws ec2 describe-addresses --filters "Name=tag:Project,Values=playmo-smartdns-dns-only"
   ```

2. **Associate old EIP with new instance:**
   ```bash
   # Get allocation ID of old EIP
   # Associate it with new instance
   ```

3. **Or update all references:**
   - Update DNS records (if using Route 53)
   - Update client configurations
   - Update documentation

## Summary

- **Elastic IP should persist** - It's a separate resource
- **Instance recreation is normal** - When user_data or other attributes change
- **Use lifecycle rules** - To prevent unnecessary recreation
- **Check plan before apply** - See what will change
- **IP should stay the same** - EIP is static and persists

