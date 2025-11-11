# Deployment and Testing Guide

## Pre-Deployment Checklist

- [ ] All code changes committed
- [ ] GitHub Secrets configured (FIREBASE_CREDENTIALS, LAMBDA_WHITELIST_URL)
- [ ] Terraform variables set correctly
- [ ] Ready to push to GitHub

## Deployment Steps

### 1. Push to GitHub

```bash
git add .
git commit -m "Add Squid proxy for SmartDNS geo-unblocking"
git push origin main
```

### 2. Monitor GitHub Actions

- Go to: https://github.com/stylz03/playmo-smartdns/actions
- Watch the deployment workflow
- Check for any errors

### 3. Wait for Deployment

- Terraform will:
  - Update security group (add proxy port 3128)
  - Update Lambda function (whitelist DNS + proxy ports)
  - Update EC2 instance (install Squid, configure proxy)
  - Restart services

**Note**: If EC2 instance already exists, Terraform will update it via user_data (may require instance restart)

## Post-Deployment Verification

### 1. Check Services on EC2

SSH into EC2 and verify:

```bash
# Check BIND9
sudo systemctl status bind9

# Check Squid
sudo systemctl status squid

# Check API
sudo systemctl status playmo-smartdns-api

# Check Squid configuration
sudo squid -k parse

# Check Squid ACL file
cat /etc/squid/whitelisted-ips.txt
```

### 2. Test DNS Resolution

```bash
# From your local machine
dig @YOUR_EC2_IP netflix.com +short
# Should return: 3.230.129.93, 52.3.144.142, 54.237.226.164

dig @YOUR_EC2_IP disneyplus.com +short
# Should return: 34.110.155.89
```

### 3. Test Proxy Access

```bash
# Test if proxy is accessible (should fail if IP not whitelisted)
curl -x http://YOUR_EC2_IP:3128 http://netflix.com

# If your IP is whitelisted, should get response
# If not whitelisted, should get "Access Denied"
```

### 4. Register Test IP

```bash
# Register your IP via API
curl -X POST http://YOUR_EC2_IP:5000/api/clients/test-client/ips \
  -H "Content-Type: application/json" \
  -d '{"ip_address": "YOUR_PUBLIC_IP", "source": "manual"}'

# Check if whitelisted
curl http://YOUR_EC2_IP:5000/api/ips/check?ip=YOUR_PUBLIC_IP
```

### 5. Verify Security Group

```bash
# Check security group rules (from AWS Console or CLI)
aws ec2 describe-security-groups \
  --group-ids YOUR_SG_ID \
  --query 'SecurityGroups[0].IpPermissions'
```

Should see:
- Port 53 (UDP/TCP) - DNS
- Port 3128 (TCP) - Proxy
- Port 5000 (TCP) - API
- Port 22 (TCP) - SSH

### 6. Test Squid ACL Update

After registering an IP, check if Squid ACL was updated:

```bash
# On EC2
cat /etc/squid/whitelisted-ips.txt
# Should contain your whitelisted IPs
```

## Client Testing

### 1. Configure DNS

Set device DNS to: `YOUR_EC2_IP`

**Android:**
- Settings → Network & Internet → Private DNS
- Enter: `YOUR_EC2_IP`

**iOS:**
- Settings → Wi-Fi → (i) → Configure DNS → Manual
- Add: `YOUR_EC2_IP`

### 2. Configure Proxy (PAC File)

Create a PAC file or configure proxy manually:

**PAC File:**
```javascript
function FindProxyForURL(url, host) {
    var streaming = [
        "netflix.com", "nflxvideo.net", "disneyplus.com", "hulu.com",
        "hbomax.com", "max.com", "peacocktv.com", "paramountplus.com"
    ];
    for (var i = 0; i < streaming.length; i++) {
        if (host.includes(streaming[i])) {
            return "PROXY YOUR_EC2_IP:3128";
        }
    }
    return "DIRECT";
}
```

**Manual Proxy (Android):**
- Settings → Wi-Fi → (i) → Advanced → Proxy → Manual
- Proxy hostname: `YOUR_EC2_IP`
- Proxy port: `3128`

### 3. Test Streaming

1. Open Netflix/Disney+ app
2. Try to access US-only content
3. Check if content loads

### 4. Verify It's Working

**Check 1: DNS Resolution**
```bash
# On device or local machine
nslookup netflix.com YOUR_EC2_IP
# Should return US CDN IPs
```

**Check 2: Proxy Connection**
- Check Squid logs on EC2:
```bash
sudo tail -f /var/log/squid/access.log
# Should see requests from your IP when streaming
```

**Check 3: IP Geolocation**
- Visit: https://whatismyipaddress.com/ip-lookup
- Enter your actual IP
- Should show your real location (not US)
- But streaming services should see US proxy IP

## Troubleshooting

### Issue: "Access Denied" from Proxy

**Cause**: IP not whitelisted

**Fix**:
1. Register IP via API
2. Check security group has port 3128 open for your IP
3. Check Squid ACL file contains your IP
4. Restart Squid: `sudo systemctl restart squid`

### Issue: DNS Not Resolving

**Cause**: Port 53 not open or BIND9 not running

**Fix**:
1. Check BIND9: `sudo systemctl status bind9`
2. Check security group allows port 53 from your IP
3. Test DNS: `dig @YOUR_EC2_IP google.com`

### Issue: Streaming Still Blocked

**Possible Causes**:
1. Proxy not configured on client
2. Only DNS configured (need both DNS + proxy)
3. Streaming service checking actual IP (not proxy IP)
4. Client not using proxy for streaming domains

**Fix**:
1. Verify proxy is configured
2. Check PAC file or proxy settings
3. Test proxy: `curl -x http://YOUR_EC2_IP:3128 http://netflix.com`
4. Check Squid logs for requests

### Issue: High Data Transfer Costs

**Cause**: All streaming going through proxy

**Fix**:
1. Verify only streaming domains use proxy
2. Check PAC file configuration
3. Monitor usage with CloudWatch
4. Set usage limits per client

## Monitoring

### CloudWatch Metrics

Set up alarms for:
- Data transfer (outbound)
- EC2 instance status
- Lambda function errors

### API Logs

Check API logs:
```bash
sudo journalctl -u playmo-smartdns-api -f
```

### Squid Logs

Check proxy access:
```bash
sudo tail -f /var/log/squid/access.log
```

## Success Criteria

✅ DNS returns US CDN IPs for streaming domains  
✅ Proxy accessible from whitelisted IPs  
✅ Security group updated with proxy port  
✅ Squid ACL updated after IP registration  
✅ Streaming apps work with US content  
✅ Data transfer costs are reasonable  

## Next Steps After Testing

1. Monitor costs for first month
2. Set up CloudWatch alarms
3. Create client onboarding process
4. Set up usage tracking per client
5. Consider pricing model if costs are high

