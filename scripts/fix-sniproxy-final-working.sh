#!/bin/bash
# Final fix for sniproxy - actually test if it works
# Run: sudo bash fix-sniproxy-final-working.sh

set -e

echo "=========================================="
echo "Final Sniproxy Fix"
echo "=========================================="

# Stop sniproxy
systemctl stop sniproxy 2>/dev/null || true

# Backup
cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Create config using the exact format that worked before (named table)
python3 << 'PYTHON_CONFIG'
config = """user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

table streaming_domains {
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
    table streaming_domains
}

listen 0.0.0.0:80 {
    proto http
    table streaming_domains
}
"""
with open('/etc/sniproxy/sniproxy.conf', 'w') as f:
    f.write(config)
print("✅ Config created with named table (this format worked before)")
PYTHON_CONFIG

# Set permissions
chmod 644 /etc/sniproxy/sniproxy.conf
chown root:root /etc/sniproxy/sniproxy.conf

# Actually test if sniproxy can start and stay running
echo ""
echo "Testing if sniproxy can actually start..."
/usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f &
SNIPROXY_PID=$!
sleep 3

if kill -0 $SNIPROXY_PID 2>/dev/null; then
    echo "✅ Sniproxy started and is running (PID: $SNIPROXY_PID)"
    kill $SNIPROXY_PID 2>/dev/null || true
    sleep 1
else
    echo "❌ Sniproxy failed to start"
    wait $SNIPROXY_PID 2>&1 || true
    echo ""
    echo "Checking for detailed error..."
    /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 | head -20 || true
    exit 1
fi

# Ensure IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p >/dev/null 2>&1 || true

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
    systemctl status sniproxy --no-pager -l | head -20
    echo ""
    echo "Ports:"
    ss -tulnp | grep sniproxy || ss -tulnp | grep -E ':80 |:443 '
    echo ""
    echo "✅ Your SmartDNS with sniproxy is ready!"
else
    echo ""
    echo "=========================================="
    echo "❌ SNIPROXY FAILED TO START"
    echo "=========================================="
    journalctl -xeu sniproxy.service --no-pager | tail -30
    exit 1
fi

