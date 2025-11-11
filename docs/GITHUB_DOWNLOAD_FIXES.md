# Fixing GitHub Download Issues on EC2

## Common Issues

### 1. **GitHub Rate Limiting (403 errors)**
GitHub may rate limit requests from EC2 IPs, especially if:
- Multiple instances are downloading simultaneously
- Too many requests in a short time
- IP is flagged for abuse

### 2. **Network Timeouts**
- Slow internet connection from EC2
- Network congestion
- DNS resolution delays

### 3. **Security Group Issues**
- Egress rules blocking HTTPS (port 443)
- VPC routing issues

## Solutions

### Solution 1: Add Timeouts and Retries (Recommended)

Update all `curl` commands to include:
```bash
curl -s -f --max-time 30 --retry 3 --retry-delay 2 <URL>
```

**Benefits:**
- `--max-time 30`: 30 second timeout
- `--retry 3`: Retry 3 times on failure
- `--retry-delay 2`: Wait 2 seconds between retries

### Solution 2: Use Alternative Download Methods

**Method A: wget (if available)**
```bash
wget --timeout=30 --tries=3 https://raw.githubusercontent.com/... -O output.sh
```

**Method B: Download with user agent**
```bash
curl -s -f -A "Mozilla/5.0" --max-time 30 <URL>
```

### Solution 3: Embed Files in user_data (Small Files Only)

For small files, embed directly in `user_data.sh`:
```bash
cat > /path/to/file <<'EOF'
<file content here>
EOF
```

**Limitation:** `user_data` has a 16KB limit, so only works for small files.

### Solution 4: Use AWS S3 Bucket

1. Upload files to S3 bucket
2. Download from S3 (faster, more reliable):
```bash
aws s3 cp s3://your-bucket/scripts/sync-sniproxy-config.sh /usr/local/bin/
```

**Benefits:**
- Faster downloads
- No rate limiting
- More reliable
- Can use IAM roles for access

### Solution 5: Use Instance Metadata/User Data

Store small configs in instance metadata or pass via Terraform variables.

### Solution 6: Download Locally and Upload via SCP

1. Download files locally
2. Upload to EC2 via SCP:
```bash
scp -i key.pem file.sh ubuntu@3.151.46.11:/tmp/
```

### Solution 7: Use GitHub API with Token (For Rate Limiting)

If rate limited, use GitHub token:
```bash
curl -H "Authorization: token YOUR_TOKEN" \
     https://api.github.com/repos/stylz03/playmo-smartdns/contents/scripts/sync-sniproxy-config.sh
```

## Diagnostic Commands

Run on EC2 to diagnose:

```bash
# Test GitHub connectivity
curl -I https://github.com

# Test raw.githubusercontent.com
curl -I https://raw.githubusercontent.com

# Test specific file
curl -v https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json

# Check DNS
nslookup raw.githubusercontent.com

# Check outbound connectivity
curl -I https://www.google.com
```

Or use the diagnostic script:
```bash
curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/diagnose-github-downloads.sh | bash
```

## Best Practices

1. **Always use timeouts and retries** in production scripts
2. **Cache downloads** - download once, reuse
3. **Use S3 for large files** or frequently accessed files
4. **Embed small configs** directly in user_data
5. **Monitor download failures** and log errors
6. **Have fallback methods** ready

## Updated user_data.sh

The `user_data.sh` has been updated to include:
- `--max-time 30`: 30 second timeout
- `--retry 3`: Retry 3 times
- `--retry-delay 2`: 2 second delay between retries

This should significantly improve download reliability.

