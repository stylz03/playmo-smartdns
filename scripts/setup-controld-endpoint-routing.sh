#!/bin/bash
# Setup ControlD endpoint routing (Tailscale-style integration)
# Routes outbound traffic through ControlD endpoints
# Usage: ./setup-controld-endpoint-routing.sh <resolver-id> [dns-primary] [dns-secondary]

set -e

CONTROLD_RESOLVER_ID="${1:-}"
CONTROLD_DNS_PRIMARY="${2:-76.76.19.19}"
CONTROLD_DNS_SECONDARY="${3:-76.76.21.21}"

if [ -z "$CONTROLD_RESOLVER_ID" ]; then
    echo "Usage: $0 <resolver-id> [dns-primary] [dns-secondary]"
    echo ""
    echo "Example: $0 abc123def456 76.76.19.19 76.76.21.21"
    echo ""
    echo "Get your Resolver ID from ControlD dashboard:"
    echo "  - Log into ControlD"
    echo "  - Go to 'Resolvers' or 'Endpoints'"
    echo "  - Copy your Resolver ID"
    exit 1
fi

echo "=========================================="
echo "Setting up ControlD Endpoint Routing"
echo "=========================================="
echo ""
echo "Resolver ID: $CONTROLD_RESOLVER_ID"
echo "DNS Primary: $CONTROLD_DNS_PRIMARY"
echo "DNS Secondary: $CONTROLD_DNS_SECONDARY"
echo ""

# 1. Configure BIND9 to forward to ControlD DNS
echo "Step 1: Configuring BIND9 to use ControlD DNS..."
if [ -f "/tmp/configure-controld-dns.sh" ]; then
    bash /tmp/configure-controld-dns.sh "$CONTROLD_DNS_PRIMARY" "$CONTROLD_DNS_SECONDARY"
else
    # Download script if not present
    curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/configure-controld-dns.sh -o /tmp/configure-controld-dns.sh
    chmod +x /tmp/configure-controld-dns.sh
    bash /tmp/configure-controld-dns.sh "$CONTROLD_DNS_PRIMARY" "$CONTROLD_DNS_SECONDARY"
fi

# 2. Test DNS resolution
echo ""
echo "Step 2: Testing ControlD DNS resolution..."
echo "Testing Netflix:"
NETFLIX_IP=$(dig @$CONTROLD_DNS_PRIMARY +short netflix.com A | head -1)
if [ -n "$NETFLIX_IP" ]; then
    echo "  ✅ Netflix resolves to: $NETFLIX_IP"
else
    echo "  ⚠️  Could not resolve Netflix"
fi

echo "Testing Disney+:"
DISNEY_IP=$(dig @$CONTROLD_DNS_PRIMARY +short disneyplus.com A | head -1)
if [ -n "$DISNEY_IP" ]; then
    echo "  ✅ Disney+ resolves to: $DISNEY_IP"
else
    echo "  ⚠️  Could not resolve Disney+"
fi

# 3. Save ControlD configuration
echo ""
echo "Step 3: Saving ControlD configuration..."
mkdir -p /etc/controld
cat > /etc/controld/config.txt <<EOF
CONTROLD_RESOLVER_ID=$CONTROLD_RESOLVER_ID
CONTROLD_DNS_PRIMARY=$CONTROLD_DNS_PRIMARY
CONTROLD_DNS_SECONDARY=$CONTROLD_DNS_SECONDARY
CONTROLD_DOH_ENDPOINT=https://dns.controld.com/$CONTROLD_RESOLVER_ID
CONFIGURED_DATE=$(date)
EOF

echo "✅ Configuration saved to /etc/controld/config.txt"

# 4. Update system resolv.conf (optional - for system DNS)
echo ""
echo "Step 4: Configuring system DNS (optional)..."
if [ -f /etc/resolv.conf ]; then
    # Backup
    cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "# ControlD DNS configuration" > /tmp/resolv.conf.controld
    echo "nameserver $CONTROLD_DNS_PRIMARY" >> /tmp/resolv.conf.controld
    echo "nameserver $CONTROLD_DNS_SECONDARY" >> /tmp/resolv.conf.controld
    echo "✅ System DNS configuration created (backup in /etc/resolv.conf.backup.*)"
    echo "   Note: /etc/resolv.conf may be managed by systemd-resolved"
fi

# 5. Test BIND9 forwarding
echo ""
echo "Step 5: Testing BIND9 forwarding to ControlD..."
LOCAL_NETFLIX=$(dig @127.0.0.1 +short netflix.com A | head -1)
if [ -n "$LOCAL_NETFLIX" ]; then
    echo "  ✅ BIND9 forwarding working: Netflix -> $LOCAL_NETFLIX"
else
    echo "  ⚠️  BIND9 forwarding test failed"
fi

echo ""
echo "=========================================="
echo "✅ ControlD Endpoint Routing Setup Complete"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Resolver ID: $CONTROLD_RESOLVER_ID"
echo "  DNS Primary: $CONTROLD_DNS_PRIMARY"
echo "  DNS Secondary: $CONTROLD_DNS_SECONDARY"
echo "  DoH Endpoint: https://dns.controld.com/$CONTROLD_RESOLVER_ID"
echo ""
echo "Next Steps:"
echo "1. Test DNS from client:"
echo "   nslookup netflix.com 3.151.46.11"
echo ""
echo "2. Set client DNS to EC2 IP: 3.151.46.11"
echo ""
echo "3. Test streaming services in browser"
echo ""
echo "4. ControlD handles all geo-unblocking automatically!"
echo ""

