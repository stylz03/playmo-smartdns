# Client IP Whitelisting Guide

## Quick Whitelist

Your IP has been whitelisted: **102.32.126.36**

## How to Whitelist Additional IPs

### Option 1: Lambda Function (Recommended)

```bash
curl -X POST https://wjpxg3gay5ba3scu2n3brfrsai0igxyt.lambda-url.us-east-2.on.aws/ \
  -H "Content-Type: application/json" \
  -d '{"ip": "YOUR_IP_ADDRESS"}'
```

### Option 2: PowerShell

```powershell
Invoke-RestMethod -Uri "https://wjpxg3gay5ba3scu2n3brfrsai0igxyt.lambda-url.us-east-2.on.aws/" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"ip": "YOUR_IP_ADDRESS"}'
```

### Option 3: AWS CLI

```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-0a9d5b82bfd5fe829 \
  --protocol udp \
  --port 53 \
  --cidr YOUR_IP/32 \
  --region us-east-2

aws ec2 authorize-security-group-ingress \
  --group-id sg-0a9d5b82bfd5fe829 \
  --protocol tcp \
  --port 53 \
  --cidr YOUR_IP/32 \
  --region us-east-2

aws ec2 authorize-security-group-ingress \
  --group-id sg-0a9d5b82bfd5fe829 \
  --protocol tcp \
  --port 3128 \
  --cidr YOUR_IP/32 \
  --region us-east-2
```

## What Gets Whitelisted

When you whitelist an IP, it gets access to:
- **DNS (UDP/TCP port 53)** - For DNS resolution
- **Proxy (TCP port 3128)** - For streaming content proxy

## After Whitelisting

1. **Clear DNS cache** on your device:
   - Restart device, OR
   - Toggle airplane mode on/off

2. **Test streaming services**:
   - Netflix
   - Disney+
   - Hulu
   - Other streaming apps

3. **If still not working**, configure proxy:
   - Proxy hostname: `3.151.46.11`
   - Proxy port: `3128`
   - Only for streaming domains

## Current Whitelisted IPs

- `102.32.126.36` (Your current IP)

## Find Your IP

Visit: https://whatismyipaddress.com

Or run:
```bash
curl ifconfig.me
```

