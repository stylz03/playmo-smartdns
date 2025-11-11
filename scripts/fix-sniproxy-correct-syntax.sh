#!/bin/bash
# Fix sniproxy with correct syntax - using named table reference
# Run: sudo bash fix-sniproxy-correct-syntax.sh

set -e

echo "=========================================="
echo "Fixing sniproxy with correct syntax"
echo "=========================================="

# Stop sniproxy
sudo systemctl stop sniproxy 2>/dev/null || true

# Backup
if [ -f /etc/sniproxy/sniproxy.conf ]; then
    sudo cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S)
fi

# Remove old config
sudo rm -f /etc/sniproxy/sniproxy.conf

# Create config with named table (correct syntax)
echo "Creating config with named table syntax..."
sudo python3 << 'PYTHON_CONFIG'
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

print("✅ Config file created with named table syntax")
PYTHON_CONFIG

# Set permissions
sudo chmod 644 /etc/sniproxy/sniproxy.conf
sudo chown root:root /etc/sniproxy/sniproxy.conf

# Test
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
    wait $SNIPROXY_PID 2>&1 || true
    echo ""
    echo "Trying alternative syntax (inline table)..."
    # Try with inline table syntax
    sudo python3 << 'PYTHON_CONFIG2'
config2 = """user daemon
pidfile /var/run/sniproxy.pid
error_log { syslog daemon priority notice }
listen 0.0.0.0:443 {
    proto tls
    table {
        .netflix.com
        .disneyplus.com
    }
}
listen 0.0.0.0:80 {
    proto http
    table {
        .netflix.com
        .disneyplus.com
    }
}
"""
with open('/etc/sniproxy/sniproxy.conf', 'w') as f:
    f.write(config2)
print("Created minimal inline table config for testing")
PYTHON_CONFIG2
    
    sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f &
    SNIPROXY_PID2=$!
    sleep 2
    if kill -0 $SNIPROXY_PID2 2>/dev/null; then
        echo "✅ Minimal inline table works! Now creating full config..."
        # Recreate full config with inline tables
        sudo python3 << 'PYTHON_CONFIG3'
config3 = """user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
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
    f.write(config3)
print("✅ Full config created with inline tables")
PYTHON_CONFIG3
        kill $SNIPROXY_PID2 2>/dev/null || true
    else
        echo "❌ Both syntaxes failed. Showing error:"
        wait $SNIPROXY_PID2 2>&1 || true
        exit 1
    fi
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

