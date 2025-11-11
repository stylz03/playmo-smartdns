# GitHub Token Storage Options for EC2

## Current Situation

The `GH_TOKEN` is:
- ✅ Stored in GitHub Secrets (secure)
- ✅ Passed to EC2 during `user_data` (instance creation only)
- ❌ Not stored on EC2 after creation (for security)

This means you need to manually provide the token for downloads after the instance is created.

## Solution Options

### Option 1: Make Repository Public (Recommended - Easiest)

**Pros:**
- ✅ No token needed at all
- ✅ All downloads work automatically
- ✅ Simplest solution
- ✅ No security concerns (it's infrastructure code)

**Cons:**
- ⚠️ Code is publicly visible (but it's infrastructure code, usually fine)

**Steps:**
1. Go to GitHub repository
2. Settings → Danger Zone → Change visibility
3. Make it public

### Option 2: AWS Systems Manager Parameter Store (Recommended - Secure)

**Pros:**
- ✅ Secure, encrypted storage
- ✅ EC2 can retrieve it automatically via IAM role
- ✅ No manual token copying needed
- ✅ Can rotate tokens easily

**Cons:**
- ⚠️ Requires IAM role configuration
- ⚠️ Slightly more complex setup

**Steps:**
1. Store token in Parameter Store:
   ```bash
   aws ssm put-parameter \
     --name "/playmo-smartdns/github-token" \
     --value "ghp_..." \
     --type "SecureString" \
     --region us-east-2
   ```

2. Add IAM policy to EC2 instance role to allow SSM access:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Action": [
         "ssm:GetParameter",
         "ssm:GetParameters"
       ],
       "Resource": "arn:aws:ssm:us-east-2:*:parameter/playmo-smartdns/*"
     }]
   }
   ```

3. Create helper script on EC2:
   ```bash
   #!/bin/bash
   # Get token from Parameter Store
   export GH_TOKEN=$(aws ssm get-parameter \
     --name "/playmo-smartdns/github-token" \
     --with-decryption \
     --query 'Parameter.Value' \
     --output text \
     --region us-east-2)
   
   # Use token in curl commands
   curl -H "Authorization: token $GH_TOKEN" \
        https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/file.sh
   ```

### Option 3: Store in EC2 Environment Variable (Quick but Less Secure)

**Pros:**
- ✅ Quick to set up
- ✅ No manual copying needed

**Cons:**
- ⚠️ Less secure (visible in process list)
- ⚠️ Lost on instance restart (unless added to profile)

**Steps:**
1. SSH into EC2
2. Add to `/etc/environment` or `~/.bashrc`:
   ```bash
   export GH_TOKEN="ghp_..."
   ```
3. Source it:
   ```bash
   source ~/.bashrc
   ```

### Option 4: Keep Using Token Manually (Current - Most Secure)

**Pros:**
- ✅ Most secure (token never stored on EC2)
- ✅ No additional setup needed

**Cons:**
- ⚠️ Requires manual copying each time
- ⚠️ Inconvenient for frequent downloads

## Recommendation

**For development/testing:** Make repo public (Option 1)

**For production:** Use AWS Systems Manager Parameter Store (Option 2)

## Implementation

If you want to implement Option 2 (Parameter Store), I can:
1. Update Terraform to store the token in Parameter Store
2. Add IAM permissions to EC2 instance role
3. Create helper scripts for easy token retrieval
4. Update user_data.sh to retrieve token from Parameter Store

Let me know which option you prefer!

