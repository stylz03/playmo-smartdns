#!/bin/bash
# Comprehensive sniproxy diagnostic script
# Run: sudo bash diagnose-sniproxy.sh

set -e

echo "=========================================="
echo "SNIPROXY DIAGNOSTIC REPORT"
echo "=========================================="
echo ""

# Check if binary exists
echo "1. Checking sniproxy binary..."
if [ -f /usr/local/sbin/sniproxy ]; then
    echo "✅ Binary found: /usr/local/sbin/sniproxy"
    ls -lh /usr/local/sbin/sniproxy
else
    echo "❌ Binary NOT found at /usr/local/sbin/sniproxy"
    echo "Checking alternative locations..."
    which sniproxy 2>/dev/null || echo "sniproxy not in PATH"
    find /usr -name sniproxy 2>/dev/null | head -5 || echo "No sniproxy found in /usr"
fi

echo ""
echo "2. Checking config file..."
if [ -f /etc/sniproxy/sniproxy.conf ]; then
    echo "✅ Config file exists"
    echo "Config file size: $(wc -l < /etc/sniproxy/sniproxy.conf) lines"
    echo "First 10 lines:"
    head -10 /etc/sniproxy/sniproxy.conf
    echo ""
    echo "Last 10 lines:"
    tail -10 /etc/sniproxy/sniproxy.conf
else
    echo "❌ Config file NOT found"
fi

echo ""
echo "3. Checking for port conflicts..."
if sudo ss -tulnp | grep -E ':80 |:443 '; then
    echo "⚠️ Ports 80 or 443 are in use:"
    sudo ss -tulnp | grep -E ':80 |:443 '
else
    echo "✅ Ports 80 and 443 are available"
fi

echo ""
echo "4. Testing config manually (foreground mode)..."
if [ -f /usr/local/sbin/sniproxy ] && [ -f /etc/sniproxy/sniproxy.conf ]; then
    echo "Running: sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f"
    timeout 3 sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 || echo "Process exited (this is expected if config is invalid)"
else
    echo "⚠️ Cannot test - binary or config missing"
fi

echo ""
echo "5. Checking systemd service status..."
sudo systemctl status sniproxy --no-pager -l | head -20 || true

echo ""
echo "6. Recent sniproxy logs..."
echo "--- Last 30 lines of journalctl ---"
sudo journalctl -xeu sniproxy.service --no-pager | tail -30 || echo "No logs found"

echo ""
echo "7. Checking systemd service file..."
if [ -f /etc/systemd/system/sniproxy.service ]; then
    echo "✅ Service file exists:"
    cat /etc/systemd/system/sniproxy.service
else
    echo "❌ Service file NOT found"
fi

echo ""
echo "=========================================="
echo "DIAGNOSTIC COMPLETE"
echo "=========================================="

