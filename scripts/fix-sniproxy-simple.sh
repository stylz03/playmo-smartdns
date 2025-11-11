#!/bin/bash
# Simple sniproxy fix - recreate config cleanly
# Run: sudo bash fix-sniproxy-simple.sh

set -e

echo "=========================================="
echo "Fixing sniproxy configuration"
echo "=========================================="

# Backup old config
if [ -f /etc/sniproxy/sniproxy.conf ]; then
    sudo mv /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backed up old config"
fi

# Create clean config file
echo "Creating clean sniproxy configuration..."
sudo tee /etc/sniproxy/sniproxy.conf > /dev/null <<'EOF'
user daemon
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
EOF

echo "✅ Configuration file created"

# Set correct permissions
sudo chmod 644 /etc/sniproxy/sniproxy.conf
sudo chown root:root /etc/sniproxy/sniproxy.conf

# Restart sniproxy
echo "Restarting sniproxy..."
sudo systemctl daemon-reload
sudo systemctl restart sniproxy

sleep 2

# Check status
if sudo systemctl is-active --quiet sniproxy; then
    echo ""
    echo "=========================================="
    echo "✅ sniproxy is running!"
    echo "=========================================="
    sudo systemctl status sniproxy --no-pager -l | head -15
else
    echo ""
    echo "=========================================="
    echo "❌ sniproxy failed to start"
    echo "=========================================="
    echo "Error details:"
    sudo journalctl -xeu sniproxy.service --no-pager | tail -20
    echo ""
    echo "Config file content (first 20 lines):"
    head -20 /etc/sniproxy/sniproxy.conf
    exit 1
fi

