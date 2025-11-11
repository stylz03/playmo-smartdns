#!/bin/bash
# Diagnose why streaming apps aren't working despite DNS working
# Checks for common issues with Netflix, Disney+, Hulu

set -e

echo "=========================================="
echo "Diagnosing Streaming Apps Issue"
echo "=========================================="
echo ""

# 1. Check DNS resolution
echo "1. Testing DNS resolution..."
NETFLIX_IP=$(dig @127.0.0.1 +short netflix.com A | head -1)
DISNEY_IP=$(dig @127.0.0.1 +short disneyplus.com A | head -1)
HULU_IP=$(dig @127.0.0.1 +short hulu.com A | head -1)

if [ -n "$NETFLIX_IP" ]; then
    echo "  ✅ Netflix: $NETFLIX_IP"
else
    echo "  ❌ Netflix: Not resolved"
fi

if [ -n "$DISNEY_IP" ]; then
    echo "  ✅ Disney+: $DISNEY_IP"
else
    echo "  ❌ Disney+: Not resolved"
fi

if [ -n "$HULU_IP" ]; then
    echo "  ✅ Hulu: $HULU_IP"
else
    echo "  ❌ Hulu: Not resolved"
fi

# 2. Check if IPs are US-based (rough check)
echo ""
echo "2. Checking IP geolocation (rough check)..."
check_ip_range() {
    local ip=$1
    local name=$2
    # 206.253.x.x is typically Netflix CDN (US)
    # This is a rough check
    if [[ "$ip" =~ ^206\.253\. ]]; then
        echo "  ✅ $name: $ip (appears to be US CDN)"
    elif [[ "$ip" =~ ^(13\.|52\.|54\.) ]]; then
        echo "  ✅ $name: $ip (appears to be AWS US)"
    else
        echo "  ⚠️  $name: $ip (unknown location)"
    fi
}

[ -n "$NETFLIX_IP" ] && check_ip_range "$NETFLIX_IP" "Netflix"
[ -n "$DISNEY_IP" ] && check_ip_range "$DISNEY_IP" "Disney+"
[ -n "$HULU_IP" ] && check_ip_range "$HULU_IP" "Hulu"

# 3. Check for common subdomains
echo ""
echo "3. Testing common subdomains..."
test_subdomain() {
    local domain=$1
    local ip=$(dig @127.0.0.1 +short "$domain" A | head -1)
    if [ -n "$ip" ]; then
        echo "  ✅ $domain -> $ip"
    else
        echo "  ⚠️  $domain -> Not resolved"
    fi
}

test_subdomain "www.netflix.com"
test_subdomain "api.netflix.com"
test_subdomain "secure.netflix.com"
test_subdomain "app.netflix.com"
test_subdomain "www.disneyplus.com"
test_subdomain "disney.api.edge.bamgrid.com"
test_subdomain "www.hulu.com"
test_subdomain "api.hulu.com"

# 4. Check BIND9 forwarding
echo ""
echo "4. Checking BIND9 configuration..."
if grep -q "76.76.2.155\|76.76.10.155" /etc/bind/named.conf.options; then
    echo "  ✅ BIND9 forwarding to ControlD"
else
    echo "  ❌ BIND9 not forwarding to ControlD"
fi

# 5. Check zone files
echo ""
echo "5. Checking zone files..."
if [ -f /etc/bind/named.conf.local ] && grep -q "zone.*netflix\|zone.*disney\|zone.*hulu" /etc/bind/named.conf.local; then
    echo "  ⚠️  Zone files still present (may override ControlD)"
    echo "     Run: sudo bash /tmp/disable-zone-files-for-controld.sh"
else
    echo "  ✅ Zone files disabled (good)"
fi

# 6. Recommendations
echo ""
echo "=========================================="
echo "Recommendations"
echo "=========================================="
echo ""
echo "If DNS is working but apps don't:"
echo ""
echo "1. Apps may use QUIC/HTTP3 (UDP) - DNS-only can't handle this"
echo "   Solution: Use WireGuard for apps"
echo "   - Connect WireGuard on your device"
echo "   - Test apps again"
echo ""
echo "2. Apps may need additional subdomains"
echo "   Solution: Check app network logs for domains being accessed"
echo "   - Add missing domains to services.json"
echo ""
echo "3. Apps may check IP geolocation strictly"
echo "   Solution: Ensure ControlD profile is set to US location"
echo "   - Check ControlD dashboard settings"
echo ""
echo "4. Try clearing BIND9 cache:"
echo "   sudo bash /tmp/clear-bind9-cache.sh"
echo ""

