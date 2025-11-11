#!/bin/bash
# Fix sniproxy using the format that we know works (named table)
# Run: sudo bash fix-sniproxy-working-format.sh

set -e

echo "=========================================="
echo "Fixing Sniproxy (Working Format)"
echo "=========================================="

# Stop sniproxy
systemctl stop sniproxy 2>/dev/null || true

# Backup
cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Use the exact format that worked before (named table streaming_domains)
python3 << 'PYTHON_CONFIG'
config = """user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

table streaming_domains {
    .netflix.com
    .nflxvideo.net
    .nflximg.net
    .nflxext.com
    .nflxso.net
    .disneyplus.com
    .bamgrid.com
    .dssott.com
    .disney.com
    .disneystreaming.com
    .hulu.com
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
    table streaming_domains
}

listen 0.0.0.0:80 {
    proto http
    table streaming_domains
}
"""
with open('/etc/sniproxy/sniproxy.conf', 'w') as f:
    f.write(config)
print("✅ Config created with named table format (expanded domains)")
PYTHON_CONFIG

# Test config
echo ""
echo "Testing config..."
/usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f &
SNIPROXY_PID=$!
sleep 3

if kill -0 $SNIPROXY_PID 2>/dev/null; then
    echo "✅ Sniproxy started (PID: $SNIPROXY_PID)"
    kill $SNIPROXY_PID 2>/dev/null || true
    sleep 1
else
    echo "❌ Sniproxy failed to start"
    wait $SNIPROXY_PID 2>&1 || true
    echo ""
    echo "Checking error..."
    /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 | head -20 || true
    exit 1
fi

# Restart service
echo ""
echo "Restarting sniproxy service..."
systemctl daemon-reload
systemctl restart sniproxy
sleep 4

if systemctl is-active --quiet sniproxy; then
    echo ""
    echo "=========================================="
    echo "✅ SNIPROXY IS RUNNING!"
    echo "=========================================="
    systemctl status sniproxy --no-pager -l | head -15
    echo ""
    echo "✅ Expanded domain list applied"
    echo "Note: Sniproxy only handles TCP/TLS, not UDP/QUIC"
else
    echo ""
    echo "=========================================="
    echo "❌ SNIPROXY FAILED TO START"
    echo "=========================================="
    journalctl -xeu sniproxy.service --no-pager | tail -20
    exit 1
fi

