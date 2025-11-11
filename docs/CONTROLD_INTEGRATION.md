# ControlD SmartDNS Integration

Instead of building your own SmartDNS, you can leverage ControlD's existing SmartDNS infrastructure. This simplifies your setup significantly.

## How ControlD Works

ControlD provides:
- **DNS servers** with geo-unblocking built-in
- **Proxy endpoints** for routing traffic
- **Pre-configured** streaming service support

## Integration Options

### Option 1: Use ControlD DNS Only (Simplest) ⭐

**How it works:**
- Configure EC2 to use ControlD DNS servers
- ControlD handles geo-unblocking via DNS
- Traffic flows directly from EC2 to streaming services
- EC2 appears as US-based to streaming services

**Setup:**
1. Get your ControlD DNS servers from your account
2. Configure BIND9 on EC2 to forward to ControlD DNS
3. Or configure EC2 to use ControlD DNS directly

### Option 2: Use ControlD Proxy Endpoints (Recommended)

**How it works:**
- Use ControlD's proxy endpoints for streaming traffic
- Configure Nginx/WireGuard to route through ControlD proxies
- ControlD handles all geo-unblocking

**Setup:**
1. Get ControlD proxy endpoints from your account
2. Configure routing to use ControlD proxies
3. Keep WireGuard for UDP/QUIC support if needed

### Option 3: Hybrid Approach

**How it works:**
- Use ControlD DNS for browsers (SmartDNS)
- Use ControlD proxy endpoints for apps
- Best of both worlds

## ControlD DNS Configuration

### Get Your ControlD DNS Servers

From your ControlD account:
- Primary DNS: Usually something like `76.76.19.19` or custom
- Secondary DNS: Usually `76.76.21.21` or custom
- Or use your custom ControlD DNS endpoint

### Configure BIND9 to Use ControlD

Update `/etc/bind/named.conf.options`:

```bash
options {
    forwarders {
        76.76.19.19;  # Your ControlD primary DNS
        76.76.21.21;  # Your ControlD secondary DNS
    };
    forward only;
};
```

### Or Use ControlD DNS Directly

Instead of BIND9, configure clients to use ControlD DNS directly:
- DNS: `76.76.19.19` (or your custom ControlD endpoint)

## ControlD Proxy Configuration

If ControlD provides proxy endpoints:

### For Nginx Stream Proxy

Update Nginx to route through ControlD proxies:

```nginx
stream {
    upstream controld_proxy {
        server controld-proxy-endpoint:port;
    }
    
    server {
        listen 443;
        proxy_pass controld_proxy;
    }
}
```

### For WireGuard

Configure WireGuard to route through ControlD:
- Use ControlD proxy as upstream
- Or configure routing rules

## Implementation Steps

### Step 1: Get ControlD Credentials

From your ControlD account dashboard:
1. Note your DNS servers
2. Get proxy endpoints (if available)
3. Get any API keys or tokens needed

### Step 2: Update EC2 Configuration

**Option A: DNS Only**
```bash
# Update BIND9 to use ControlD DNS
sudo nano /etc/bind/named.conf.options
# Add ControlD DNS as forwarders
sudo systemctl restart bind9
```

**Option B: Proxy Endpoints**
```bash
# Configure Nginx/WireGuard to use ControlD proxies
# Update routing configuration
```

### Step 3: Update Client Configs

**For SmartDNS (Browsers):**
- Set DNS to: Your ControlD DNS server (or EC2 IP if using BIND9 forwarding)

**For Apps:**
- Use WireGuard with ControlD proxy routing
- Or use ControlD's app configuration

## Benefits

✅ **Simplified setup** - No need to maintain IP ranges
✅ **Reliable** - ControlD handles updates automatically
✅ **Better coverage** - ControlD has extensive streaming service support
✅ **Less maintenance** - ControlD updates IPs automatically

## Migration Path

1. **Keep existing setup** as backup
2. **Add ControlD DNS** to BIND9 forwarders
3. **Test** with browsers first
4. **Configure proxy endpoints** for apps
5. **Gradually migrate** clients

## Questions to Answer

1. **What DNS servers does ControlD provide?**
   - Check your ControlD account dashboard
   - Usually shown as "DNS Servers" or "SmartDNS"

2. **Does ControlD provide proxy endpoints?**
   - Some plans include proxy/VPN endpoints
   - Check your account features

3. **What's your ControlD plan?**
   - Different plans have different features
   - Some include API access, custom endpoints, etc.

## Next Steps

1. **Check your ControlD account** for:
   - DNS server addresses
   - Proxy endpoints (if available)
   - API credentials (if needed)

2. **Choose integration method:**
   - DNS only (simplest)
   - Proxy endpoints (more control)
   - Hybrid (best of both)

3. **Update configuration** based on chosen method

Let me know what ControlD provides in your account, and I'll help you integrate it!

