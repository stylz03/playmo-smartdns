# ControlD Endpoint Routing (Tailscale-Style Integration)

This guide shows how to route outbound traffic through ControlD endpoints, similar to how Tailscale integrates with ControlD.

## How Tailscale + ControlD Works

According to [Tailscale's ControlD integration](https://tailscale.com/kb/1403/control-d):
- Tailscale uses ControlD with **DNS over HTTPS (DoH)**
- ControlD acts as a **global nameserver** for the tailnet
- All DNS queries go through ControlD
- ControlD handles geo-unblocking, filtering, and routing

## Our Implementation

We'll configure:
1. **BIND9** to forward DNS queries to ControlD (DoH or standard DNS)
2. **Routing** to send outbound traffic through ControlD endpoints
3. **Nginx/WireGuard** to proxy through ControlD infrastructure

## Prerequisites

From your ControlD account, you need:
1. **Resolver ID** (Endpoint ID) - Your unique ControlD endpoint identifier
2. **DNS Servers** - ControlD DNS IPs (usually `76.76.19.19`, `76.76.21.21`)
3. **DoH Endpoint** (optional) - DNS over HTTPS URL
4. **Proxy Endpoints** (if available) - For routing traffic

## Step 1: Get ControlD Credentials

### From ControlD Dashboard:

1. **Resolver ID (Endpoint ID):**
   - Log into ControlD dashboard
   - Go to "Resolvers" or "Endpoints"
   - Note your Resolver ID (looks like: `abc123def456`)

2. **DNS Servers:**
   - Default: `76.76.19.19` (primary), `76.76.21.21` (secondary)
   - Or custom DNS if you have a custom resolver

3. **DoH Endpoint:**
   - Format: `https://<resolver-id>.controld.com/dns-query`
   - Or: `https://dns.controld.com/<resolver-id>`

4. **Proxy Endpoints** (if available):
   - Check your ControlD plan features
   - Some plans include proxy/VPN endpoints

## Step 2: Configure DNS Forwarding to ControlD

### Option A: Standard DNS Forwarding (Simplest)

Configure BIND9 to forward to ControlD DNS:

```bash
# On EC2
sudo bash /tmp/configure-controld-dns.sh 76.76.19.19 76.76.21.21
```

### Option B: DNS over HTTPS (DoH) - More Secure

Use ControlD's DoH endpoint for encrypted DNS:

```bash
# Install dns-over-https proxy (like cloudflared or stubby)
# Then configure BIND9 to forward to local DoH proxy
```

## Step 3: Route Outbound Traffic Through ControlD

### Method 1: DNS-Based Routing (Automatic)

ControlD DNS automatically returns geo-unblocked IPs:
- Streaming domains resolve to US IPs
- Traffic flows directly to those IPs
- EC2 appears as US-based to services

**Configuration:**
- BIND9 forwards to ControlD DNS
- Clients use EC2 IP as DNS
- ControlD handles geo-unblocking automatically

### Method 2: Proxy Routing (If ControlD Provides Proxies)

If ControlD provides proxy endpoints:

```nginx
# Nginx stream proxy through ControlD
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

### Method 3: WireGuard + ControlD DNS

Use WireGuard with ControlD DNS:
- WireGuard routes streaming traffic
- ControlD DNS provides geo-unblocked IPs
- Best of both worlds

## Step 4: Implementation Script

Create a script to configure everything:

```bash
#!/bin/bash
# Configure ControlD endpoint routing (Tailscale-style)

CONTROLD_RESOLVER_ID="${1:-}"
CONTROLD_DNS_PRIMARY="${2:-76.76.19.19}"
CONTROLD_DNS_SECONDARY="${3:-76.76.21.21}"

if [ -z "$CONTROLD_RESOLVER_ID" ]; then
    echo "Usage: $0 <resolver-id> [dns-primary] [dns-secondary]"
    echo "Example: $0 abc123def456 76.76.19.19 76.76.21.21"
    exit 1
fi

# 1. Configure BIND9 to forward to ControlD DNS
echo "Configuring BIND9 to use ControlD DNS..."
sudo bash /tmp/configure-controld-dns.sh "$CONTROLD_DNS_PRIMARY" "$CONTROLD_DNS_SECONDARY"

# 2. Configure system DNS to use ControlD (optional)
echo "Configuring system DNS..."
echo "nameserver $CONTROLD_DNS_PRIMARY" | sudo tee /etc/resolv.conf.controld
echo "nameserver $CONTROLD_DNS_SECONDARY" | sudo tee -a /etc/resolv.conf.controld

# 3. Test DNS resolution
echo "Testing ControlD DNS..."
dig @$CONTROLD_DNS_PRIMARY netflix.com +short
dig @$CONTROLD_DNS_PRIMARY disneyplus.com +short

echo "✅ ControlD integration complete!"
echo "Resolver ID: $CONTROLD_RESOLVER_ID"
echo "DNS: $CONTROLD_DNS_PRIMARY, $CONTROLD_DNS_SECONDARY"
```

## Architecture

```
┌─────────────────────────────────────────┐
│  Client Device                          │
├─────────────────────────────────────────┤
│  DNS: 3.151.46.11 (EC2)                 │
│  └─> BIND9 (EC2)                        │
│      └─> ControlD DNS (76.76.19.19)      │
│          └─> Returns geo-unblocked IPs   │
│                                          │
│  Traffic:                               │
│  └─> Direct to geo-unblocked IPs        │
│      (via ControlD DNS resolution)     │
└─────────────────────────────────────────┘
```

## Benefits

✅ **Automatic geo-unblocking** - ControlD handles it
✅ **No IP range maintenance** - ControlD updates automatically
✅ **Better coverage** - ControlD has extensive service support
✅ **Simplified setup** - Less configuration needed
✅ **Reliable** - ControlD infrastructure is well-maintained

## Testing

1. **Test DNS resolution:**
   ```bash
   dig @76.76.19.19 netflix.com
   dig @76.76.19.19 disneyplus.com
   ```

2. **Test from client:**
   - Set DNS to EC2 IP (3.151.46.11)
   - Visit streaming sites
   - Should see US content

3. **Check IP resolution:**
   ```bash
   # Should return US IPs
   nslookup netflix.com 3.151.46.11
   ```

## Migration from Current Setup

1. **Keep existing setup** as backup
2. **Configure ControlD DNS** forwarding
3. **Test** with browsers first
4. **Gradually migrate** clients
5. **Remove custom IP ranges** (no longer needed)

## Next Steps

1. **Get your ControlD Resolver ID** from dashboard
2. **Run configuration script** with your credentials
3. **Test DNS resolution** to verify it's working
4. **Update client DNS** to use EC2 IP
5. **Test streaming services**

Let me know your ControlD Resolver ID and DNS servers, and I'll create the complete configuration!

