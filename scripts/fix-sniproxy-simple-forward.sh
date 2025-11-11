#!/bin/bash
# Fix sniproxy with correct syntax - simple transparent forwarding
# Run: sudo bash fix-sniproxy-simple-forward.sh

set -e

echo "=========================================="
echo "Fixing Sniproxy with Simple Forwarding"
echo "=========================================="

# Stop sniproxy
systemctl stop sniproxy 2>/dev/null || true

# Backup config
cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S)

# Sniproxy should forward transparently - when it sees SNI for a domain in the table,
# it forwards to the original destination. The table just lists domains to match.
# No resolver needed if we use the default behavior.

python3 << 'PYTHON_CONFIG'
config = """user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

# Table for streaming domains
# When SNI matches these domains, sniproxy forwards to original destination
table {
    .netflix.com
    .disneyplus.com
    .hulu.com
    .nflxvideo.net
    .bamgrid.com
    .hbomax.com
    .max.com
    .peacocktv.com
    .paramountplus.com
    .paramount.com
    .espn.com
    .espnplus.com
    .primevideo.com
    .amazonvideo.com
    .tv.apple.com
    .sling.com
    .discoveryplus.com
    .tubi.tv
    .crackle.com
    .roku.com
    .tntdrama.com
    .tbs.com
    .flosports.tv
    .magellantv.com
    .aetv.com
    .directv.com
    .britbox.com
    .dazn.com
    .fubo.tv
    .philo.com
    .dishanywhere.com
    .xumo.tv
    .hgtv.com
    .amcplus.com
    .mgmplus.com
}

listen 0.0.0.0:443 {
    proto tls
    table {
        .netflix.com
        .disneyplus.com
        .hulu.com
        .nflxvideo.net
        .bamgrid.com
        .hbomax.com
        .max.com
        .peacocktv.com
        .paramountplus.com
        .paramount.com
        .espn.com
        .espnplus.com
        .primevideo.com
        .amazonvideo.com
        .tv.apple.com
        .sling.com
        .discoveryplus.com
        .tubi.tv
        .crackle.com
        .roku.com
        .tntdrama.com
        .tbs.com
        .flosports.tv
        .magellantv.com
        .aetv.com
        .directv.com
        .britbox.com
        .dazn.com
        .fubo.tv
        .philo.com
        .dishanywhere.com
        .xumo.tv
        .hgtv.com
        .amcplus.com
        .mgmplus.com
    }
}

listen 0.0.0.0:80 {
    proto http
    table {
        .netflix.com
        .disneyplus.com
        .hulu.com
        .nflxvideo.net
        .bamgrid.com
        .hbomax.com
        .max.com
        .peacocktv.com
        .paramountplus.com
        .paramount.com
        .espn.com
        .espnplus.com
        .primevideo.com
        .amazonvideo.com
        .tv.apple.com
        .sling.com
        .discoveryplus.com
        .tubi.tv
        .crackle.com
        .roku.com
        .tntdrama.com
        .tbs.com
        .flosports.tv
        .magellantv.com
        .aetv.com
        .directv.com
        .britbox.com
        .dazn.com
        .fubo.tv
        .philo.com
        .dishanywhere.com
        .xumo.tv
        .hgtv.com
        .amcplus.com
        .mgmplus.com
    }
}
"""
with open('/etc/sniproxy/sniproxy.conf', 'w') as f:
    f.write(config)
print("✅ Config created (simple table-based forwarding)")
PYTHON_CONFIG

# Ensure IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p >/dev/null 2>&1 || true

# Test config manually first
echo ""
echo "Testing config manually..."
if timeout 3 /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 | head -5; then
    echo "⚠️ Config test output shown"
else
    TEST_OUTPUT=$(timeout 3 /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 || true)
    if echo "$TEST_OUTPUT" | grep -q "Unable to load\|error parsing"; then
        echo "❌ Config has errors:"
        echo "$TEST_OUTPUT"
        echo ""
        echo "Restoring previous config..."
        cp /etc/sniproxy/sniproxy.conf.backup.* /etc/sniproxy/sniproxy.conf 2>/dev/null || true
        exit 1
    fi
fi

# Restart sniproxy
echo ""
echo "Restarting sniproxy..."
systemctl daemon-reload
systemctl restart sniproxy
sleep 3

if systemctl is-active --quiet sniproxy; then
    echo "✅ Sniproxy restarted successfully"
    systemctl status sniproxy --no-pager -l | head -15
else
    echo "❌ Sniproxy failed to start"
    echo "Error:"
    journalctl -xeu sniproxy.service --no-pager | tail -20
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Sniproxy configured"
echo "=========================================="
echo ""
echo "Note: Sniproxy forwards based on SNI matching."
echo "If streaming apps still don't work, the issue might be:"
echo "1. Apps using hardcoded IPs (bypass DNS)"
echo "2. Apps checking IP geolocation"
echo "3. Apps requiring specific TLS/SSL configuration"
echo ""
echo "Test from your phone again after a few seconds."

