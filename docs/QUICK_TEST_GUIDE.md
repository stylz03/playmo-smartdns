# Quick Test Guide - Post Deployment

## ✅ Deployment Successful!

Your SmartDNS with proxy is now deployed. Follow these steps to test:

## Step 1: Verify Services Are Running

SSH into your EC2 instance and check services:

```bash
# Check BIND9 DNS server
sudo systemctl status bind9
# Should show: active (running)

# Check Squid proxy
sudo systemctl status squid
# Should show: active (running)

# Check API
sudo systemctl status playmo-smartdns-api
# Should show: active (running)
```

## Step 2: Test DNS Resolution

Test that DNS returns US CDN IPs:

```bash
# From your local machine or EC2
dig @3.151.46.11 netflix.com +short
# Should return: 3.230.129.93, 52.3.144.142, 54.237.226.164

dig @3.151.46.11 disneyplus.com +short
# Should return: 34.110.155.89

dig @3.151.46.11 hulu.com +short
# Should return: 23.185.0.1, 23.185.0.2
```

## Step 3: Verify Zone Files Were Created

```bash
# On EC2
ls -la /etc/bind/zones/ | head -10
# Should show zone files like: db.netflix_com, db.disneyplus_com, etc.

# Check a zone file
cat /etc/bind/zones/db.netflix_com
# Should show the zone file with US IPs
```

## Step 4: Register Your IP Address

Register your IP to whitelist it for DNS and proxy access:

```bash
# Replace YOUR_IP with your actual public IP
curl -X POST http://3.151.46.11:5000/api/clients/test-client/ips \
  -H "Content-Type: application/json" \
  -d '{"ip_address": "YOUR_IP", "source": "manual"}'

# Check if whitelisted
curl http://3.151.46.11:5000/api/ips/check?ip=YOUR_IP
```

This will:
- Whitelist your IP in security group (ports 53 and 3128)
- Update Squid ACL to allow your IP
- Store IP in Firestore

## Step 5: Test Proxy Access

After registering your IP, test proxy:

```bash
# Test proxy (should work if IP is whitelisted)
curl -x http://3.151.46.11:3128 http://netflix.com
# Should return HTML (not "Access Denied")

# Check Squid logs
sudo tail -f /var/log/squid/access.log
# Should show your requests
```

## Step 6: Test on Your Device

### Configure DNS:
- Set DNS to: `3.151.46.11`

### Configure Proxy (for streaming domains only):

**Option A: PAC File (Recommended)**
Create a PAC file that only proxies streaming domains:
```javascript
function FindProxyForURL(url, host) {
    var streaming = ["netflix.com", "disneyplus.com", "hulu.com", "hbomax.com"];
    for (var i = 0; i < streaming.length; i++) {
        if (host.includes(streaming[i])) {
            return "PROXY 3.151.46.11:3128";
        }
    }
    return "DIRECT";
}
```

**Option B: Manual Proxy (Android)**
- Settings → Wi-Fi → (i) → Advanced → Proxy → Manual
- Proxy hostname: `3.151.46.11`
- Proxy port: `3128`

### Test Streaming:
1. Open Netflix/Disney+ app
2. Try to access US-only content
3. Should work if both DNS and proxy are configured

## Troubleshooting

### DNS Not Resolving
```bash
# Check BIND9
sudo systemctl status bind9
sudo named-checkconf

# Check zone files exist
ls -la /etc/bind/zones/
```

### Proxy Access Denied
```bash
# Check if IP is whitelisted
curl http://3.151.46.11:5000/api/ips/check?ip=YOUR_IP

# Check Squid ACL
cat /etc/squid/whitelisted-ips.txt

# Check security group (from AWS Console or CLI)
aws ec2 describe-security-groups --group-ids sg-0a9d5b82bfd5fe829
```

### API Not Working
```bash
# Check API status
sudo systemctl status playmo-smartdns-api

# Check API logs
sudo journalctl -u playmo-smartdns-api -n 50

# Test API health
curl http://3.151.46.11:5000/health
```

## Success Indicators

✅ DNS returns US CDN IPs for streaming domains  
✅ Squid proxy is running and accessible  
✅ API is running and can whitelist IPs  
✅ Zone files created successfully  
✅ Security group updated with proxy port  
✅ Streaming apps work with US content  

## Next Steps

1. Monitor costs (set up CloudWatch alarms)
2. Test with multiple clients
3. Set up usage tracking
4. Consider pricing model if costs are high

