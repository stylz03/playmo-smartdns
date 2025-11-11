#!/bin/bash
# Final fix for sniproxy - using correct syntax
# Run: sudo bash fix-sniproxy-final.sh

set -e

echo "=========================================="
echo "Final sniproxy config fix"
echo "=========================================="

# Stop sniproxy
sudo systemctl stop sniproxy 2>/dev/null || true

# Backup
if [ -f /etc/sniproxy/sniproxy.conf ]; then
    sudo cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S)
fi

# Remove old config
sudo rm -f /etc/sniproxy/sniproxy.conf

# Create config - the issue might be that we need to reference the table name, not redefine it
echo "Creating config with correct syntax..."
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

print("✅ Config file created")
PYTHON_CONFIG

# Set permissions
sudo chmod 644 /etc/sniproxy/sniproxy.conf
sudo chown root:root /etc/sniproxy/sniproxy.conf

# Test with verbose output
echo ""
echo "Testing config (this will show the actual error if any)..."
ERROR_OUTPUT=$(sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 &)
SNIPROXY_PID=$!
sleep 2

if kill -0 $SNIPROXY_PID 2>/dev/null; then
    echo "✅ Config test passed - sniproxy started!"
    kill $SNIPROXY_PID 2>/dev/null || true
else
    echo "❌ Config test failed!"
    wait $SNIPROXY_PID 2>&1 || echo "$ERROR_OUTPUT"
    echo ""
    echo "Let's check the config file line by line around potential issues:"
    echo "Line 48 (proto tls):"
    sed -n '46,50p' /etc/sniproxy/sniproxy.conf
    echo ""
    echo "Line 89 (proto http):"
    sed -n '87,91p' /etc/sniproxy/sniproxy.conf
    exit 1
fi

# Restart service
echo ""
echo "Restarting sniproxy service..."
sudo systemctl daemon-reload
sudo systemctl restart sniproxy
sleep 3

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

