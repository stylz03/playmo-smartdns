#!/bin/bash
# Test WireGuard split-tunneling to verify it's working correctly

set -e

echo "=========================================="
echo "Testing WireGuard Split-Tunneling"
echo "=========================================="

# Check if WireGuard is connected
if ! command -v wg >/dev/null 2>&1; then
    echo "❌ WireGuard tools not installed"
    exit 1
fi

echo ""
echo "1. Checking WireGuard connection..."
if ip link show wg0 >/dev/null 2>&1; then
    echo "✅ WireGuard interface (wg0) is active"
    wg show
else
    echo "❌ WireGuard interface (wg0) not found"
    echo "Make sure WireGuard is connected on your device"
    exit 1
fi

echo ""
echo "2. Checking routing table..."
echo "WireGuard routes:"
ip route show table all | grep wg0 || echo "No wg0 routes found"

echo ""
echo "3. Testing IP resolution..."
echo "Your public IP (should be your regular IP, not EC2):"
PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me 2>/dev/null || echo "Could not determine")
echo "  $PUBLIC_IP"

if [[ "$PUBLIC_IP" == "3.151.46.11" ]]; then
    echo "⚠️  WARNING: Your IP is the EC2 IP - split-tunneling may not be working!"
    echo "   All traffic is going through VPN instead of just streaming IPs"
else
    echo "✅ Your regular IP is showing (split-tunneling working)"
fi

echo ""
echo "4. Testing streaming service IP resolution..."
echo "Netflix IPs:"
dig +short netflix.com A | head -3 || echo "Could not resolve"

echo "Disney+ IPs:"
dig +short disneyplus.com A | head -3 || echo "Could not resolve"

echo ""
echo "5. Checking if streaming IPs are in AllowedIPs..."
if [ -f "/tmp/client1.conf" ] || [ -f "$HOME/client1.conf" ]; then
    CONFIG_FILE="/tmp/client1.conf"
    [ -f "$HOME/client1.conf" ] && CONFIG_FILE="$HOME/client1.conf"
    
    echo "Reading config: $CONFIG_FILE"
    ALLOWED_IPS=$(grep "AllowedIPs" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')
    IP_COUNT=$(echo "$ALLOWED_IPS" | tr ',' '\n' | wc -l)
    echo "  Found $IP_COUNT IP ranges in AllowedIPs"
    
    # Check if Netflix IPs are covered
    NETFLIX_IP=$(dig +short netflix.com A | head -1)
    if [ -n "$NETFLIX_IP" ]; then
        NETFLIX_NETWORK=$(echo "$NETFLIX_IP" | cut -d. -f1-3)
        if echo "$ALLOWED_IPS" | grep -q "$NETFLIX_NETWORK"; then
            echo "  ✅ Netflix IP range ($NETFLIX_NETWORK.0/24) found in AllowedIPs"
        else
            echo "  ⚠️  Netflix IP range ($NETFLIX_NETWORK.0/24) NOT in AllowedIPs"
            echo "     This might be why Netflix isn't working"
        fi
    fi
else
    echo "⚠️  Config file not found - cannot check AllowedIPs"
fi

echo ""
echo "=========================================="
echo "Troubleshooting Tips"
echo "=========================================="
echo ""
echo "If split-tunneling isn't working:"
echo "1. Check WireGuard app settings"
echo "2. Verify AllowedIPs contains streaming IP ranges (not 0.0.0.0/0)"
echo "3. Re-generate IP ranges: sudo bash /tmp/setup-client.sh client1"
echo ""
echo "If apps still don't work:"
echo "1. Streaming services change IPs frequently"
echo "2. Some apps use additional endpoints not in services.json"
echo "3. Try updating IP ranges or adding more domains to services.json"

