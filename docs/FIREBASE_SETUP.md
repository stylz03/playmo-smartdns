# Firebase Integration Setup Guide

## Overview

The Playmo SmartDNS project integrates with Firebase for client management, IP whitelisting, and dashboard visualization. This guide covers the complete setup process.

## Prerequisites

1. Firebase project created
2. Firestore Database enabled
3. Firebase Authentication enabled
4. Service account key generated

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Follow the setup wizard
4. Enable **Firestore Database** (Native mode)
5. Enable **Authentication** (optional, for client apps)

## Step 2: Create Service Account

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file (keep it secure!)
4. This file contains your service account credentials

## Step 3: Configure Firestore Collections

The API automatically creates these collections:

### Collections Structure

#### `clients`
```json
{
  "id": "client_123",
  "name": "Client Name",
  "email": "client@example.com",
  "status": "active",
  "ip_addresses": [
    {
      "ip": "192.168.1.100",
      "created_at": "2025-01-15T10:00:00Z",
      "updated_at": "2025-01-15T10:00:00Z",
      "source": "manual",
      "is_active": true
    }
  ],
  "created_at": "2025-01-15T10:00:00Z",
  "updated_at": "2025-01-15T10:00:00Z",
  "metadata": {}
}
```

#### `ip_addresses`
```json
{
  "id": "ip_123",
  "client_id": "client_123",
  "ip_address": "192.168.1.100",
  "is_whitelisted": true,
  "whitelisted_at": "2025-01-15T10:00:00Z",
  "created_at": "2025-01-15T10:00:00Z",
  "updated_at": "2025-01-15T10:00:00Z",
  "source": "manual"
}
```

#### `whitelist_entries`
```json
{
  "id": "whitelist_123",
  "ip_address": "192.168.1.100",
  "client_id": "client_123",
  "whitelisted_at": "2025-01-15T10:00:00Z",
  "whitelisted_by": "system",
  "protocol": "udp"
}
```

#### `api_logs`
```json
{
  "id": "log_123",
  "endpoint": "/api/clients",
  "method": "POST",
  "status": 201,
  "data": {},
  "timestamp": "2025-01-15T10:00:00Z",
  "ip": "192.168.1.1"
}
```

## Step 4: Set Up Firestore Security Rules

Go to Firestore → Rules and add:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write for authenticated users (adjust as needed)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Or allow public read (for dashboard) but restrict write
    match /clients/{clientId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /ip_addresses/{ipId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /whitelist_entries/{entryId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /api_logs/{logId} {
      allow read: if request.auth != null;
      allow write: if true; // API can write logs
    }
  }
}
```

## Step 5: Add GitHub Secrets

1. Go to your GitHub repository → Settings → Secrets and variables → Actions
2. Add the following secrets:

### `FIREBASE_CREDENTIALS`
- Value: The entire contents of your Firebase service account JSON file
- Format: Single-line JSON string (or use `jq -c .` to compress)

### `LAMBDA_WHITELIST_URL` (Optional)
- Value: Your Lambda function URL (will be auto-populated from Terraform output)

## Step 6: Deploy

The GitHub Actions workflow will automatically:
1. Inject Firebase credentials into the EC2 instance
2. Install and start the API service
3. Configure the Lambda whitelist URL

## Step 7: Verify API

After deployment, test the API:

```bash
# Health check
curl http://YOUR_EC2_IP:5000/health

# Get all clients
curl http://YOUR_EC2_IP:5000/api/clients

# Create a client
curl -X POST http://YOUR_EC2_IP:5000/api/clients \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Client",
    "email": "test@example.com"
  }'

# Add IP for client
curl -X POST http://YOUR_EC2_IP:5000/api/clients/CLIENT_ID/ips \
  -H "Content-Type: application/json" \
  -d '{
    "ip_address": "192.168.1.100",
    "source": "manual"
  }'
```

## Firebase Studio Visualization

1. Install [Firebase Studio](https://firebase.tools/) or use Firebase Console
2. Connect to your Firestore database
3. View collections: `clients`, `ip_addresses`, `whitelist_entries`, `api_logs`
4. Create custom dashboards for:
   - Client management
   - IP whitelisting status
   - API usage statistics
   - Real-time IP changes

## Mobile App Integration

### Android TV / Google TV
- Use Firebase SDK for Android
- Authenticate users with Firebase Auth
- Read client data from Firestore
- Call API endpoints for IP management

### tvOS (Apple TV)
- Use Firebase SDK for iOS
- Authenticate users with Firebase Auth
- Read client data from Firestore
- Call API endpoints for IP management

## Automation Features

### Automatic IP Whitelisting
When a client IP is added via the API:
1. IP is stored in Firestore
2. Lambda function is called automatically
3. Security group is updated
4. Whitelist status is tracked

### IP Change Detection (Future Enhancement)
- Set up Cloud Functions to monitor IP changes
- Automatically update whitelist when IP changes
- Notify clients via push notifications

## Security Considerations

1. **API Access**: Consider adding authentication to API endpoints
2. **Firestore Rules**: Restrict write access appropriately
3. **Service Account**: Keep credentials secure, never commit to git
4. **API CIDR**: Restrict `api_cidr` variable in Terraform for production

## Troubleshooting

### API not starting
```bash
# SSH into EC2 instance
sudo systemctl status playmo-smartdns-api
sudo journalctl -u playmo-smartdns-api -f
```

### Firebase connection issues
- Check FIREBASE_CREDENTIALS environment variable
- Verify service account has Firestore permissions
- Check Firestore security rules

### Lambda whitelist not working
- Verify LAMBDA_WHITELIST_URL is set
- Check Lambda function logs
- Verify security group permissions

