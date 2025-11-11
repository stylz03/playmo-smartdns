# GitHub Personal Access Token Setup

## Step 1: Create GitHub Personal Access Token

1. Go to GitHub → Settings → Developer settings
   - Or direct link: https://github.com/settings/tokens

2. Click "Personal access tokens" → "Tokens (classic)"

3. Click "Generate new token" → "Generate new token (classic)"

4. Configure the token:
   - **Note**: `playmo-smartdns-deploy` (or any name you prefer)
   - **Expiration**: Choose duration (90 days, 1 year, or no expiration)
   - **Scopes**: Check `repo` (Full control of private repositories)
     - This gives access to read private repo files

5. Click "Generate token"

6. **IMPORTANT**: Copy the token immediately - you won't see it again!
   - It will look like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## Step 2: Add Token to GitHub Secrets

1. Go to your repository: https://github.com/stylz03/playmo-smartdns

2. Click "Settings" → "Secrets and variables" → "Actions"

3. Click "New repository secret"

4. Configure:
   - **Name**: `GH_TOKEN` ⚠️ **Important**: Cannot use `GITHUB_TOKEN` - GitHub reserves that prefix!
   - **Secret**: Paste your token (the `ghp_...` value)

5. Click "Add secret"

## Step 3: Update Terraform Variables

The token will be passed via GitHub Actions workflow automatically.

## Step 4: Update user_data.sh

The `user_data.sh` has been updated to use the token if provided.

## Step 5: Update GitHub Actions Workflow

The workflow will automatically use the token from secrets.

## Testing

After setup, the next deployment will:
1. Use the token for all GitHub downloads
2. Successfully download scripts from private repo
3. No more 404 errors!

## Security Notes

- ✅ Token is stored in GitHub Secrets (encrypted)
- ✅ Only used during deployment
- ✅ Can be revoked anytime from GitHub settings
- ✅ Minimal permissions (only `repo` scope)

## Revoking Token

If you need to revoke:
1. GitHub → Settings → Developer settings → Personal access tokens
2. Find your token
3. Click "Revoke"

Then create a new one and update the secret.

