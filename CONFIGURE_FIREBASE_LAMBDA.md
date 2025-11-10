# Configure Firebase and Lambda on EC2

## Step 1: Get Firebase Credentials
The Firebase credentials should be in GitHub Secrets. You'll need to:
1. Go to GitHub → Settings → Secrets → Actions
2. Copy the `FIREBASE_CREDENTIALS` value (it's a JSON string)

## Step 2: Get Lambda URL
From Terraform outputs, the Lambda URL is:
`https://wjpxg3gay5ba3scu2n3brfrsai0igxyt.lambda-url.us-east-2.on.aws/`

## Step 3: Update Systemd Service

Run these commands on the EC2 instance:

```bash
# Stop the service first
sudo systemctl stop playmo-smartdns-api

# Edit the service file
sudo nano /etc/systemd/system/playmo-smartdns-api.service
```

In the editor, update the Environment lines:
- Replace `Environment="FIREBASE_CREDENTIALS="` with your actual Firebase credentials JSON
- Replace `Environment="LAMBDA_WHITELIST_URL="` with the Lambda URL

Or use this command to update it directly (replace YOUR_FIREBASE_JSON with actual JSON):

```bash
sudo sed -i 's|Environment="FIREBASE_CREDENTIALS="|Environment="FIREBASE_CREDENTIALS=YOUR_FIREBASE_JSON"|' /etc/systemd/system/playmo-smartdns-api.service
sudo sed -i 's|Environment="LAMBDA_WHITELIST_URL="|Environment="LAMBDA_WHITELIST_URL=https://wjpxg3gay5ba3scu2n3brfrsai0igxyt.lambda-url.us-east-2.on.aws/"|' /etc/systemd/system/playmo-smartdns-api.service
```

## Step 4: Reload and Restart
```bash
sudo systemctl daemon-reload
sudo systemctl restart playmo-smartdns-api
sudo systemctl status playmo-smartdns-api
```

## Step 5: Test
```bash
curl http://localhost:5000/health
```

You should see `"firebase_connected": true` and `"lambda_configured": true`

