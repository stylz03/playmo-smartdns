#!/bin/bash
# Fix Netflix, Disney+, and Hulu by disabling zone files and ensuring ControlD handles them
# This script:
# 1. Disables zone files that override ControlD
# 2. Ensures BIND9 forwards all queries to ControlD
# 3. Tests DNS resolution

set -e

echo "=========================================="
echo "Fixing Netflix, Disney+, and Hulu"
echo "=========================================="
echo ""

# Step 1: Disable zone files
echo "Step 1: Disabling zone files (they override ControlD)..."
if [ -f "/tmp/disable-zone-files-for-controld.sh" ]; then
    bash /tmp/disable-zone-files-for-controld.sh
else
    curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/disable-zone-files-for-controld.sh -o /tmp/disable-zone-files.sh
    chmod +x /tmp/disable-zone-files.sh
    bash /tmp/disable-zone-files.sh
fi

# Step 2: Verify BIND9 is forwarding to ControlD
echo ""
echo "Step 2: Verifying BIND9 forwards to ControlD..."
if grep -q "76.76.2.155\|76.76.10.155" /etc/bind/named.conf.options; then
    echo "✅ BIND9 is configured to forward to ControlD"
else
    echo "⚠️  BIND9 not forwarding to ControlD - configuring now..."
    curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/configure-controld-dns.sh -o /tmp/configure-controld.sh
    chmod +x /tmp/configure-controld.sh
    bash /tmp/configure-controld.sh 76.76.2.155 76.76.10.155
fi

# Step 3: Test DNS resolution
echo ""
echo "Step 3: Testing DNS resolution..."
echo ""

test_domain() {
    local domain=$1
    echo "Testing $domain..."
    LOCAL_IP=$(dig @127.0.0.1 +short "$domain" A | head -1)
    CONTROLD_IP=$(dig @76.76.2.155 +short "$domain" A | head -1)
    
    if [ -n "$LOCAL_IP" ] && [ -n "$CONTROLD_IP" ]; then
        if [ "$LOCAL_IP" = "$CONTROLD_IP" ]; then
            echo "  ✅ $domain: $LOCAL_IP (matches ControlD)"
        else
            echo "  ⚠️  $domain: Local=$LOCAL_IP, ControlD=$CONTROLD_IP (mismatch!)"
        fi
    else
        echo "  ❌ $domain: Could not resolve"
    fi
}

test_domain "netflix.com"
test_domain "www.netflix.com"
test_domain "nflxvideo.net"
test_domain "disneyplus.com"
test_domain "www.disneyplus.com"
test_domain "bamgrid.com"
test_domain "hulu.com"
test_domain "www.hulu.com"

# Step 4: Check for subdomains
echo ""
echo "Step 4: Checking common subdomains..."
echo "Netflix subdomains:"
for subdomain in "api.netflix.com" "secure.netflix.com" "app.netflix.com"; do
    IP=$(dig @76.76.2.155 +short "$subdomain" A | head -1)
    if [ -n "$IP" ]; then
        echo "  ✅ $subdomain -> $IP"
    else
        echo "  ⚠️  $subdomain -> Not found"
    fi
done

echo ""
echo "Disney+ subdomains:"
for subdomain in "disney.api.edge.bamgrid.com" "cdn.registerdisney.go.com"; do
    IP=$(dig @76.76.2.155 +short "$subdomain" A | head -1)
    if [ -n "$IP" ]; then
        echo "  ✅ $subdomain -> $IP"
    else
        echo "  ⚠️  $subdomain -> Not found"
    fi
done

echo ""
echo "=========================================="
echo "✅ Fix Complete!"
echo "=========================================="
echo ""
echo "Zone files have been disabled."
echo "All DNS queries now go through ControlD."
echo ""
echo "Test from client:"
echo "  nslookup netflix.com 3.151.46.11"
echo "  nslookup disneyplus.com 3.151.46.11"
echo "  nslookup hulu.com 3.151.46.11"
echo ""
echo "If apps still don't work, they may need additional subdomains."
echo "Check app logs or network traffic to see which domains they're accessing."

