#!/bin/bash
# Fix sniproxy port conflicts
# Run: sudo bash fix-sniproxy-ports.sh

set -e

echo "=========================================="
echo "Fixing sniproxy port conflicts"
echo "=========================================="

# Check what's using ports 80 and 443
echo "Checking for port conflicts..."
echo ""
echo "Port 80:"
sudo ss -tulnp | grep ':80 ' || echo "Port 80 is free"

echo ""
echo "Port 443:"
sudo ss -tulnp | grep ':443 ' || echo "Port 443 is free"

# Check for common services that might be using port 80
echo ""
echo "Checking for common services..."
if systemctl is-active --quiet apache2 2>/dev/null; then
    echo "⚠️ Apache2 is running - stopping it..."
    sudo systemctl stop apache2
    sudo systemctl disable apache2
fi

if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "⚠️ Nginx is running - stopping it..."
    sudo systemctl stop nginx
    sudo systemctl disable nginx
fi

if systemctl is-active --quiet lighttpd 2>/dev/null; then
    echo "⚠️ Lighttpd is running - stopping it..."
    sudo systemctl stop lighttpd
    sudo systemctl disable lighttpd
fi

# Check again
echo ""
echo "Rechecking ports after stopping services..."
echo "Port 80:"
sudo ss -tulnp | grep ':80 ' || echo "✅ Port 80 is now free"

echo ""
echo "Port 443:"
sudo ss -tulnp | grep ':443 ' || echo "✅ Port 443 is now free"

# If port 80 is still in use, we can either:
# 1. Remove HTTP listener (only use HTTPS)
# 2. Use different ports

echo ""
echo "Restarting sniproxy..."
sudo systemctl daemon-reload
sudo systemctl restart sniproxy
sleep 3

if sudo systemctl is-active --quiet sniproxy; then
    echo ""
    echo "=========================================="
    echo "✅ SNIPROXY IS RUNNING!"
    echo "=========================================="
    sudo systemctl status sniproxy --no-pager -l | head -15
    echo ""
    echo "Ports in use by sniproxy:"
    sudo ss -tulnp | grep sniproxy || sudo ss -tulnp | grep -E ':80 |:443 '
else
    echo ""
    echo "=========================================="
    echo "❌ SNIPROXY STILL FAILED"
    echo "=========================================="
    sudo journalctl -xeu sniproxy.service --no-pager | tail -20
    
    # If port 80 is still an issue, create config without HTTP listener
    if sudo ss -tulnp | grep -q ':80 '; then
        echo ""
        echo "Port 80 is still in use. Creating config with HTTPS only..."
        sudo systemctl stop sniproxy
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
"""
with open('/etc/sniproxy/sniproxy.conf', 'w') as f:
    f.write(config)
print("✅ Config created with HTTPS only (port 443)")
PYTHON_CONFIG
        
        sudo systemctl restart sniproxy
        sleep 3
        
        if sudo systemctl is-active --quiet sniproxy; then
            echo "✅ SNIPROXY IS RUNNING (HTTPS only)!"
            sudo systemctl status sniproxy --no-pager -l | head -15
        else
            echo "❌ Still failed. Check logs above."
            exit 1
        fi
    fi
fi

