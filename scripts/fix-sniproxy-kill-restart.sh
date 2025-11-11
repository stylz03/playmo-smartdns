#!/bin/bash
# Kill old sniproxy processes and restart cleanly
# Run: sudo bash fix-sniproxy-kill-restart.sh

set -e

echo "=========================================="
echo "Killing old sniproxy and restarting"
echo "=========================================="

# Stop the service first
echo "Stopping sniproxy service..."
sudo systemctl stop sniproxy 2>/dev/null || true

# Kill any remaining sniproxy processes
echo "Killing any remaining sniproxy processes..."
sudo pkill -9 sniproxy 2>/dev/null || true

# Wait a moment for ports to be released
sleep 2

# Verify ports are free
echo ""
echo "Checking if ports are free..."
PORT80=$(sudo ss -tulnp | grep ':80 ' || echo "free")
PORT443=$(sudo ss -tulnp | grep ':443 ' || echo "free")

if echo "$PORT80" | grep -q "free" && echo "$PORT443" | grep -q "free"; then
    echo "✅ Ports 80 and 443 are free"
else
    echo "⚠️ Ports still in use:"
    echo "Port 80: $PORT80"
    echo "Port 443: $PORT443"
    echo "Waiting 3 more seconds..."
    sleep 3
fi

# Ensure we have the correct config (with named table)
if ! grep -q "table streaming_domains" /etc/sniproxy/sniproxy.conf 2>/dev/null; then
    echo ""
    echo "Recreating config with correct syntax..."
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
print("✅ Config recreated")
PYTHON_CONFIG
fi

# Reload systemd and start
echo ""
echo "Starting sniproxy service..."
sudo systemctl daemon-reload
sudo systemctl start sniproxy
sleep 3

# Check status
if sudo systemctl is-active --quiet sniproxy; then
    echo ""
    echo "=========================================="
    echo "✅ SNIPROXY IS RUNNING!"
    echo "=========================================="
    sudo systemctl status sniproxy --no-pager -l | head -20
    echo ""
    echo "Ports in use:"
    sudo ss -tulnp | grep sniproxy || sudo ss -tulnp | grep -E ':80 |:443 '
else
    echo ""
    echo "=========================================="
    echo "❌ SNIPROXY FAILED TO START"
    echo "=========================================="
    sudo journalctl -xeu sniproxy.service --no-pager | tail -25
    
    # Check if there are still processes
    if pgrep sniproxy > /dev/null; then
        echo ""
        echo "Found sniproxy processes still running:"
        ps aux | grep sniproxy | grep -v grep
        echo ""
        echo "Killing them..."
        sudo pkill -9 sniproxy
        sleep 2
        echo "Trying to start again..."
        sudo systemctl start sniproxy
        sleep 3
        if sudo systemctl is-active --quiet sniproxy; then
            echo "✅ SNIPROXY IS NOW RUNNING!"
            sudo systemctl status sniproxy --no-pager -l | head -15
        else
            echo "❌ Still failing. Please check the logs above."
            exit 1
        fi
    else
        exit 1
    fi
fi

