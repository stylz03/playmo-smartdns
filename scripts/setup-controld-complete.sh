#!/bin/bash
# Complete ControlD setup with your specific credentials
# Resolver ID: 12lwu5ien99
# DNS: 76.76.2.155, 76.76.10.155

set -e

CONTROLD_RESOLVER_ID="12lwu5ien99"
CONTROLD_DNS_PRIMARY="76.76.2.155"
CONTROLD_DNS_SECONDARY="76.76.10.155"
CONTROLD_DOH_ENDPOINT="https://dns.controld.com/12lwu5ien99"
CONTROLD_DOT_ENDPOINT="12lwu5ien99.dns.controld.com"

echo "=========================================="
echo "ControlD Endpoint Routing Setup"
echo "=========================================="
echo ""
echo "Resolver ID: $CONTROLD_RESOLVER_ID"
echo "DNS Primary: $CONTROLD_DNS_PRIMARY"
echo "DNS Secondary: $CONTROLD_DNS_SECONDARY"
echo "DoH Endpoint: $CONTROLD_DOH_ENDPOINT"
echo "DoT Endpoint: $CONTROLD_DOT_ENDPOINT"
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

echo "Testing Hulu:"
HULU_IP=$(dig @$CONTROLD_DNS_PRIMARY +short hulu.com A | head -1)
if [ -n "$HULU_IP" ]; then
    echo "  ✅ Hulu resolves to: $HULU_IP"
else
    echo "  ⚠️  Could not resolve Hulu"
fi

# 3. Test BIND9 forwarding
echo ""
echo "Step 3: Testing BIND9 forwarding to ControlD..."
LOCAL_NETFLIX=$(dig @127.0.0.1 +short netflix.com A | head -1)
if [ -n "$LOCAL_NETFLIX" ]; then
    echo "  ✅ BIND9 forwarding working: Netflix -> $LOCAL_NETFLIX"
else
    echo "  ⚠️  BIND9 forwarding test failed"
fi

# 4. Save ControlD configuration
echo ""
echo "Step 4: Saving ControlD configuration..."
mkdir -p /etc/controld
cat > /etc/controld/config.txt <<EOF
CONTROLD_RESOLVER_ID=$CONTROLD_RESOLVER_ID
CONTROLD_DNS_PRIMARY=$CONTROLD_DNS_PRIMARY
CONTROLD_DNS_SECONDARY=$CONTROLD_DNS_SECONDARY
CONTROLD_DOH_ENDPOINT=$CONTROLD_DOH_ENDPOINT
CONTROLD_DOT_ENDPOINT=$CONTROLD_DOT_ENDPOINT
CONFIGURED_DATE=$(date)
EOF

echo "✅ Configuration saved to /etc/controld/config.txt"

# 5. Display configuration summary
echo ""
echo "=========================================="
echo "✅ ControlD Setup Complete!"
echo "=========================================="
echo ""
echo "Configuration Summary:"
echo "  Resolver ID: $CONTROLD_RESOLVER_ID"
echo "  DNS Primary: $CONTROLD_DNS_PRIMARY"
echo "  DNS Secondary: $CONTROLD_DNS_SECONDARY"
echo "  DoH Endpoint: $CONTROLD_DOH_ENDPOINT"
echo "  DoT Endpoint: $CONTROLD_DOT_ENDPOINT"
echo ""
echo "EC2 Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo '3.151.46.11')"
echo ""
echo "Next Steps:"
echo "1. Test DNS from client:"
echo "   nslookup netflix.com $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo '3.151.46.11')"
echo ""
echo "2. Set client DNS to EC2 IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo '3.151.46.11')"
echo ""
echo "3. Test streaming services in browser"
echo ""
echo "4. ControlD handles all geo-unblocking automatically!"
echo "   No need to maintain IP ranges anymore!"
echo ""

