# Testing sniproxy Deployment

## Quick Verification Commands

### 1. Check sniproxy Service Status
```bash
sudo systemctl status sniproxy
```

Expected: `Active: active (running)`

### 2. Check if sniproxy is Listening
```bash
sudo ss -tulnp | grep sniproxy
```

Expected output:
```
tcp   LISTEN 0  128  0.0.0.0:443  0.0.0.0:*  users:(("sniproxy",pid=XXXX,fd=3))
tcp   LISTEN 0  128  0.0.0.0:80   0.0.0.0:*  users:(("sniproxy",pid=XXXX,fd=4))
```

### 3. Check sniproxy Configuration
```bash
cat /etc/sniproxy/sniproxy.conf
```

Should show all streaming domains from `services.json` in the table and listen blocks.

### 4. Check DNS Resolution
```bash
dig @127.0.0.1 netflix.com +short
dig @127.0.0.1 disneyplus.com +short
```

Expected: Should resolve to EC2 Elastic IP (e.g., `3.151.46.11`)

### 5. Check Zone Files
```bash
ls -la /etc/bind/zones/
cat /etc/bind/zones/db.netflix_com
```

Should show zone files with A records pointing to EC2 IP.

### 6. Test sniproxy Logs
```bash
sudo journalctl -u sniproxy -n 50 --no-pager
```

## Testing from Client Device

### 1. Set DNS
- Set your device DNS to: `3.151.46.11` (or your EC2 Elastic IP)

### 2. Test DNS Resolution
```bash
# From your local machine
nslookup netflix.com 3.151.46.11
```

Should return: `3.151.46.11` (EC2 IP)

### 3. Test HTTPS Connection
```bash
# Test if sniproxy is forwarding HTTPS
curl -v https://netflix.com --resolve netflix.com:443:3.151.46.11
```

Should connect through sniproxy and forward to actual Netflix servers.

### 4. Test Streaming Apps
- Open Netflix, Disney+, Hulu, etc. on your device
- They should now work because:
  1. DNS resolves to EC2 IP
  2. HTTPS traffic goes to EC2
  3. sniproxy inspects SNI and forwards to actual servers
  4. Streaming services see US IP (EC2 location)

## Troubleshooting

### sniproxy Not Running
```bash
# Check logs
sudo journalctl -u sniproxy -n 100 --no-pager

# Restart service
sudo systemctl restart sniproxy

# Check config syntax
sudo sniproxy -c /etc/sniproxy/sniproxy.conf -t
```

### DNS Not Resolving to EC2 IP
```bash
# Check BIND9 status
sudo systemctl status bind9

# Check zone files
ls -la /etc/bind/zones/

# Reload BIND9
sudo systemctl reload bind9
```

### sniproxy Config Not Synced
```bash
# Manually sync config
sudo /usr/local/bin/sync-sniproxy-config.sh /tmp/services.json /etc/sniproxy/sniproxy.conf

# Or download and sync
curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json -o /tmp/services.json
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
EC2_IP=$EC2_IP sudo /usr/local/bin/sync-sniproxy-config.sh /tmp/services.json /etc/sniproxy/sniproxy.conf
```

## Expected Behavior

✅ **DNS**: Streaming domains resolve to EC2 IP  
✅ **HTTPS**: Traffic flows through sniproxy  
✅ **SNI Inspection**: sniproxy reads domain from SNI  
✅ **Forwarding**: Traffic forwarded to actual streaming servers  
✅ **Geo-unblocking**: Streaming services see US IP  

## Next Steps

1. ✅ Verify sniproxy is running
2. ✅ Test DNS resolution
3. ✅ Test streaming apps
4. ✅ Monitor logs for any issues
5. ✅ Add more domains to `services.json` if needed (auto-syncs!)

