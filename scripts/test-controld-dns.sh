#!/bin/bash
# Test ControlD DNS resolution and compare with direct queries

set -e

echo "=========================================="
echo "Testing ControlD DNS Resolution"
echo "=========================================="
echo ""

# Test domains
DOMAINS=(
    "netflix.com"
    "www.netflix.com"
    "nflxvideo.net"
    "disneyplus.com"
    "www.disneyplus.com"
    "bamgrid.com"
    "hulu.com"
    "www.hulu.com"
)

CONTROLD_PRIMARY="76.76.2.155"
EC2_DNS="127.0.0.1"

echo "Comparing DNS resolution:"
echo "  Local (BIND9 -> ControlD): @$EC2_DNS"
echo "  Direct ControlD: @$CONTROLD_PRIMARY"
echo ""

for domain in "${DOMAINS[@]}"; do
    echo "Testing $domain:"
    
    # Get IPs
    LOCAL_IP=$(dig @$EC2_DNS +short "$domain" A | head -1 || echo "N/A")
    CONTROLD_IP=$(dig @$CONTROLD_PRIMARY +short "$domain" A | head -1 || echo "N/A")
    
    if [ "$LOCAL_IP" != "N/A" ] && [ "$CONTROLD_IP" != "N/A" ]; then
        if [ "$LOCAL_IP" = "$CONTROLD_IP" ]; then
            echo "  ✅ Match: $LOCAL_IP"
        else
            echo "  ⚠️  Local: $LOCAL_IP, ControlD: $CONTROLD_IP"
            echo "     (Different IPs are normal - could be load balancing or caching)"
        fi
    elif [ "$LOCAL_IP" != "N/A" ]; then
        echo "  ✅ Local: $LOCAL_IP (ControlD: N/A)"
    elif [ "$CONTROLD_IP" != "N/A" ]; then
        echo "  ⚠️  Local: N/A, ControlD: $CONTROLD_IP"
    else
        echo "  ❌ Both failed to resolve"
    fi
done

echo ""
echo "=========================================="
echo "Testing Subdomains"
echo "=========================================="
echo ""

SUBDOMAINS=(
    "api.netflix.com"
    "secure.netflix.com"
    "app.netflix.com"
    "disney.api.edge.bamgrid.com"
    "cdn.registerdisney.go.com"
)

for subdomain in "${SUBDOMAINS[@]}"; do
    IP=$(dig @$EC2_DNS +short "$subdomain" A | head -1 || echo "N/A")
    if [ "$IP" != "N/A" ]; then
        echo "  ✅ $subdomain -> $IP"
    else
        echo "  ⚠️  $subdomain -> Not resolved"
    fi
done

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "If you see IPs (even if different), DNS is working!"
echo "Different IPs are normal due to:"
echo "  - Load balancing (multiple valid IPs)"
echo "  - Caching (BIND9 may cache results)"
echo "  - Query source (ControlD may return different IPs)"
echo ""
echo "Test from your client device:"
echo "  nslookup netflix.com 3.151.46.11"
echo ""
echo "If apps still don't work:"
echo "  1. Clear BIND9 cache: sudo bash /tmp/clear-bind9-cache.sh"
echo "  2. Check app network logs for additional domains"
echo "  3. Verify client DNS is set to: 3.151.46.11"

