# Client Setup Guide for Playmo SmartDNS

## Overview

Playmo SmartDNS uses a hybrid approach:
1. **DNS Server**: Returns US CDN IPs for streaming domains
2. **Proxy Server**: Routes streaming traffic through US proxy (port 3128)

## Prerequisites

1. Your IP must be whitelisted via the API
2. DNS must be set to the SmartDNS server
3. Proxy must be configured for streaming domains only

## Setup Instructions

### Step 1: Register Your IP

Register your IP address via the API:

```bash
curl -X POST http://YOUR_EC2_IP:5000/api/clients/YOUR_CLIENT_ID/ips \
  -H "Content-Type: application/json" \
  -d '{"ip_address": "YOUR_PUBLIC_IP", "source": "manual"}'
```

This will:
- Whitelist your IP in the security group (DNS port 53 and proxy port 3128)
- Update Squid ACL to allow your IP to use the proxy

### Step 2: Configure DNS

Set your device's DNS server to: `YOUR_EC2_IP` (e.g., `3.151.46.11`)

**Android:**
- Settings → Network & Internet → Private DNS
- Enter: `YOUR_EC2_IP`

**iOS:**
- Settings → Wi-Fi → (i) next to network → Configure DNS
- Manual → Add: `YOUR_EC2_IP`

**Windows:**
- Settings → Network & Internet → Change adapter options
- Right-click network → Properties → IPv4 → Use DNS: `YOUR_EC2_IP`

**macOS:**
- System Preferences → Network → Advanced → DNS
- Add: `YOUR_EC2_IP`

### Step 3: Configure Proxy (Streaming Domains Only)

**Important**: Only configure proxy for streaming domains. Regular web traffic should go directly.

#### Option A: PAC (Proxy Auto-Configuration) File (Recommended)

Create a PAC file that only proxies streaming domains:

```javascript
function FindProxyForURL(url, host) {
    // List of streaming domains
    var streamingDomains = [
        "netflix.com", "nflxvideo.net",
        "disneyplus.com", "bamgrid.com",
        "hulu.com", "hbomax.com", "max.com",
        "peacocktv.com", "paramountplus.com", "paramount.com",
        "espn.com", "espnplus.com",
        "primevideo.com", "amazonvideo.com",
        "tv.apple.com", "sling.com",
        "discoveryplus.com", "tubi.tv",
        "crackle.com", "roku.com",
        "tntdrama.com", "tbs.com",
        "flosports.tv", "magellantv.com",
        "aetv.com", "directv.com",
        "britbox.com", "dazn.com",
        "fubo.tv", "philo.com",
        "dishanywhere.com", "xumo.tv",
        "hgtv.com", "amcplus.com",
        "mgmplus.com"
    ];
    
    // Check if host is a streaming domain
    for (var i = 0; i < streamingDomains.length; i++) {
        if (host.includes(streamingDomains[i])) {
            return "PROXY YOUR_EC2_IP:3128";
        }
    }
    
    // Direct connection for all other domains
    return "DIRECT";
}
```

**Android:**
- Settings → Wi-Fi → (i) → Advanced → Proxy → Manual
- Proxy hostname: `YOUR_EC2_IP`
- Proxy port: `3128`
- Bypass proxy for: (leave empty, use PAC file instead)

**iOS:**
- iOS doesn't support PAC files directly. Use a VPN app or configure per-app.

**Windows:**
- Settings → Network & Internet → Proxy
- Use setup script: `http://YOUR_EC2_IP:5000/proxy.pac`

**macOS:**
- System Preferences → Network → Advanced → Proxies
- Automatic Proxy Configuration: `http://YOUR_EC2_IP:5000/proxy.pac`

#### Option B: Manual Proxy Configuration (Per App)

Some apps allow manual proxy configuration:

**Netflix App:**
- Configure system proxy (see above)

**Browser:**
- Chrome/Edge: Settings → Advanced → System → Open proxy settings
- Firefox: Settings → Network Settings → Manual proxy → HTTP Proxy: `YOUR_EC2_IP:3128`

### Step 4: Test Configuration

1. **Test DNS:**
   ```bash
   dig @YOUR_EC2_IP netflix.com +short
   # Should return US CDN IPs
   ```

2. **Test Proxy:**
   ```bash
   curl -x http://YOUR_EC2_IP:3128 http://netflix.com
   # Should work if your IP is whitelisted
   ```

3. **Test Streaming:**
   - Open Netflix/Disney+ app
   - Try to access US-only content
   - Should work if both DNS and proxy are configured correctly

## Troubleshooting

### "Service not available in your location"
- Check if your IP is whitelisted: `curl http://YOUR_EC2_IP:5000/api/ips/check?ip=YOUR_IP`
- Verify DNS is set correctly
- Verify proxy is configured for streaming domains
- Check if you're on WiFi (cellular often blocks custom DNS/proxy)

### Proxy connection refused
- Your IP might not be whitelisted
- Check security group allows port 3128 from your IP
- Verify Squid is running: `sudo systemctl status squid`

### DNS not resolving
- Check if DNS server is accessible: `dig @YOUR_EC2_IP google.com`
- Verify port 53 is open in security group
- Check BIND9 is running: `sudo systemctl status bind9`

## API Endpoints

- `GET /health` - Check API status
- `POST /api/clients/{client_id}/ips` - Register IP
- `GET /api/ips/check?ip={ip}` - Check if IP is whitelisted
- `GET /api/stats` - Get statistics

## Security Notes

- Only whitelisted IPs can use the proxy
- Proxy only works for streaming domains
- Regular web traffic goes directly (no proxy)
- All traffic is logged for monitoring

