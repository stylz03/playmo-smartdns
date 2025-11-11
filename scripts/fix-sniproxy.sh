#!/bin/bash
# Fix sniproxy configuration and service issues
# Run: sudo bash fix-sniproxy.sh

set -e

echo "=========================================="
echo "Diagnosing and Fixing sniproxy"
echo "=========================================="

# Check if sniproxy binary exists
if [ ! -f /usr/local/sbin/sniproxy ]; then
    echo "❌ sniproxy binary not found at /usr/local/sbin/sniproxy"
    echo "Please install sniproxy first using install-sniproxy-simple.sh"
    exit 1
fi

echo "✅ sniproxy binary found"

# Check for port conflicts
echo ""
echo "Checking for port conflicts..."
if sudo ss -tulnp | grep -E ':80 |:443 ' | grep -v sniproxy; then
    echo "⚠️  Port 80 or 443 is in use by another service"
    echo "Services using these ports:"
    sudo ss -tulnp | grep -E ':80 |:443 '
else
    echo "✅ Ports 80 and 443 are available"
fi

# Check current config
echo ""
echo "Validating current sniproxy configuration..."
if sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -t 2>&1; then
    echo "✅ Configuration is valid"
else
    echo "❌ Configuration has errors, fixing..."
    
    # Create corrected config
    sudo tee /etc/sniproxy/sniproxy.conf > /dev/null <<'EOF'
user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

# Table for streaming domains
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

# Listen on port 443 for HTTPS traffic
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

# Listen on port 80 for HTTP traffic
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
EOF

    echo "✅ Created corrected configuration"
    
    # Validate again
    if sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -t 2>&1; then
        echo "✅ New configuration is valid"
    else
        echo "❌ Configuration still has errors:"
        sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -t
        exit 1
    fi
fi

# Fix systemd service if needed
echo ""
echo "Checking systemd service configuration..."
if ! grep -q "Type=forking" /etc/systemd/system/sniproxy.service 2>/dev/null; then
    echo "⚠️  Service type not set to forking, fixing..."
    sudo sed -i '/\[Service\]/a Type=forking' /etc/systemd/system/sniproxy.service
    sudo systemctl daemon-reload
    echo "✅ Service configuration updated"
else
    echo "✅ Service type is correct"
fi

# Restart sniproxy
echo ""
echo "Restarting sniproxy..."
sudo systemctl daemon-reload
sudo systemctl restart sniproxy

sleep 2

# Check status
echo ""
echo "Checking sniproxy status..."
if sudo systemctl is-active --quiet sniproxy; then
    echo "✅ sniproxy is running!"
    sudo systemctl status sniproxy --no-pager -l | head -15
else
    echo "❌ sniproxy failed to start. Checking logs:"
    sudo journalctl -xeu sniproxy.service --no-pager | tail -20
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ sniproxy fix complete!"
echo "=========================================="

