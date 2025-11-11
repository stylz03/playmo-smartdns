#!/bin/bash
# Test sniproxy forwarding and diagnose issues
# Run: sudo bash test-sniproxy-forwarding.sh

set -e

echo "=========================================="
echo "Testing Sniproxy Forwarding"
echo "=========================================="

EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "3.151.46.11")

echo "EC2 IP: $EC2_IP"
echo ""

# 1. Check sniproxy status
echo "1. Sniproxy Service Status:"
if systemctl is-active --quiet sniproxy; then
    echo "✅ Sniproxy is running"
    systemctl status sniproxy --no-pager -l | head -10
else
    echo "❌ Sniproxy is NOT running"
    exit 1
fi

echo ""
echo "2. Sniproxy Configuration:"
if [ -f /etc/sniproxy/sniproxy.conf ]; then
    echo "✅ Config file exists"
    echo "Config summary:"
    grep -E "^table|^listen|proto" /etc/sniproxy/sniproxy.conf | head -10
else
    echo "❌ Config file missing"
    exit 1
fi

echo ""
echo "3. Port Listening Status:"
ss -tulnp | grep -E '443|80' | grep sniproxy || echo "⚠️ Sniproxy not listening on expected ports"

echo ""
echo "4. Testing DNS Resolution:"
echo "netflix.com should resolve to $EC2_IP:"
dig @127.0.0.1 netflix.com +short || echo "❌ DNS failed"

echo ""
echo "5. Testing Sniproxy Forwarding (from EC2):"
echo "This test tries to connect through sniproxy..."
echo ""
echo "Testing HTTPS connection to netflix.com via sniproxy:"
timeout 5 curl -v -k --resolve netflix.com:443:$EC2_IP https://netflix.com 2>&1 | head -20 || echo "❌ Connection failed or timeout"

echo ""
echo "6. Sniproxy Logs (last 20 lines):"
journalctl -u sniproxy -n 20 --no-pager || echo "No logs found"

echo ""
echo "=========================================="
echo "DIAGNOSIS"
echo "=========================================="
echo ""
echo "If sniproxy is running but forwarding fails, the issue might be:"
echo "1. Sniproxy table configuration - needs to forward transparently"
echo "2. Network routing - EC2 needs to forward traffic"
echo "3. IP forwarding not enabled on EC2"
echo ""
echo "Checking IP forwarding..."
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" = "1" ]; then
    echo "✅ IP forwarding is enabled"
else
    echo "❌ IP forwarding is DISABLED - this is required for sniproxy!"
    echo "Enabling IP forwarding..."
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    echo "✅ IP forwarding enabled"
fi

echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "If forwarding still doesn't work, sniproxy might need a different config."
echo "The current config uses 'table streaming_domains' which should forward"
echo "transparently, but we may need to explicitly configure forwarding."

