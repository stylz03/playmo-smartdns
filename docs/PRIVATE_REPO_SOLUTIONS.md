# Solutions for Private Repository

Since the repository is private, `raw.githubusercontent.com` URLs require authentication and will fail.

## Option 1: Make Repository Public (Recommended)

**Easiest solution:**
1. Go to GitHub repository
2. Settings → Danger Zone → Change visibility
3. Make it public
4. All raw.githubusercontent.com URLs will work

**Pros:**
- ✅ No code changes needed
- ✅ All existing scripts work
- ✅ Simplest solution

**Cons:**
- ⚠️ Code is publicly visible (but it's infrastructure code, usually fine)

## Option 2: Use GitHub Personal Access Token

Add token to GitHub Secrets and use in downloads:

```bash
# In user_data.sh or scripts
GITHUB_TOKEN="${GITHUB_TOKEN}"
curl -H "Authorization: token $GITHUB_TOKEN" \
     https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/file.sh
```

**Steps:**
1. Create GitHub Personal Access Token (Settings → Developer settings → Personal access tokens)
2. Add to GitHub Secrets as `GITHUB_TOKEN`
3. Pass to Terraform as `TF_VAR_github_token`
4. Use in user_data.sh

## Option 3: Embed Files in user_data.sh

For small files, embed directly (but user_data has 16KB limit):

```bash
# In user_data.sh
cat > /path/to/file <<'EOF'
<file content>
EOF
```

**Limitation:** Only works for small files due to 16KB limit.

## Option 4: Use AWS S3 Bucket

Upload scripts to S3, download from there:

```bash
# Upload to S3
aws s3 cp scripts/sync-sniproxy-config.sh s3://your-bucket/scripts/

# Download in user_data.sh
aws s3 cp s3://your-bucket/scripts/sync-sniproxy-config.sh /usr/local/bin/
```

**Pros:**
- ✅ Fast and reliable
- ✅ No authentication issues
- ✅ Can use IAM roles

## Option 5: Download Locally and Upload via SCP

1. Download files locally
2. Upload to EC2 via SCP:

```bash
scp -i key.pem scripts/sync-sniproxy-config.sh ubuntu@3.151.46.11:/tmp/
```

## Option 6: Use GitHub API with Token

```bash
# Get file content via API
curl -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/repos/stylz03/playmo-smartdns/contents/scripts/sync-sniproxy-config.sh \
     | jq -r '.content' | base64 -d > /tmp/file.sh
```

## Recommended Approach

**For immediate fix:** Use direct paste (no downloads needed) - already provided

**For long-term:** 
1. Make repo public (if acceptable)
2. OR use S3 bucket for scripts
3. OR add GitHub token support

## Current Workaround

For now, use the direct paste commands I provided - they don't require any GitHub downloads and work immediately.

