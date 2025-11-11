#!/bin/bash
# Fix sniproxy using Python (most reliable method)
# Run: sudo bash fix-sniproxy-python.sh

set -e

echo "=========================================="
echo "Fixing sniproxy config using Python"
echo "=========================================="

# Stop sniproxy
sudo systemctl stop sniproxy 2>/dev/null || true

# Backup old config
if [ -f /etc/sniproxy/sniproxy.conf ]; then
    sudo cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backed up old config"
fi

# Remove old config
sudo rm -f /etc/sniproxy/sniproxy.conf

# Create config using Python (avoids all encoding issues)
echo "Creating config file using Python..."
sudo python3 << 'PYTHON_CONFIG'
config = """user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

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

print("✅ Config file created successfully")
PYTHON_CONFIG

# Set permissions
sudo chmod 644 /etc/sniproxy/sniproxy.conf
sudo chown root:root /etc/sniproxy/sniproxy.conf

# Verify
echo ""
echo "Verifying config..."
PROTO_TLS_COUNT=$(grep -c "proto tls" /etc/sniproxy/sniproxy.conf || echo "0")
PROTO_HTTP_COUNT=$(grep -c "proto http" /etc/sniproxy/sniproxy.conf || echo "0")

if [ "$PROTO_TLS_COUNT" -eq "1" ] && [ "$PROTO_HTTP_COUNT" -eq "1" ]; then
    echo "✅ Config verified: proto tls=$PROTO_TLS_COUNT, proto http=$PROTO_HTTP_COUNT"
else
    echo "❌ Config verification failed: proto tls=$PROTO_TLS_COUNT, proto http=$PROTO_HTTP_COUNT"
    exit 1
fi

# Check for corruption
if grep -q "roto" /etc/sniproxy/sniproxy.conf && ! grep -q "proto" /etc/sniproxy/sniproxy.conf; then
    echo "❌ ERROR: Found 'roto' without 'proto' - corruption detected!"
    exit 1
fi

# Test config
echo ""
echo "Testing config..."
sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f &
SNIPROXY_PID=$!
sleep 2

if kill -0 $SNIPROXY_PID 2>/dev/null; then
    echo "✅ Config test passed!"
    kill $SNIPROXY_PID 2>/dev/null || true
else
    echo "❌ Config test failed!"
    TEST_OUTPUT=$(wait $SNIPROXY_PID 2>&1 || true)
    echo "$TEST_OUTPUT"
    exit 1
fi

# Restart service
echo ""
echo "Restarting sniproxy service..."
sudo systemctl daemon-reload
sudo systemctl restart sniproxy
sleep 3

# Check status
if sudo systemctl is-active --quiet sniproxy; then
    echo ""
    echo "=========================================="
    echo "✅ SNIPROXY IS RUNNING!"
    echo "=========================================="
    sudo systemctl status sniproxy --no-pager -l | head -15
else
    echo ""
    echo "=========================================="
    echo "❌ SNIPROXY FAILED TO START"
    echo "=========================================="
    sudo journalctl -xeu sniproxy.service --no-pager | tail -20
    exit 1
fi

