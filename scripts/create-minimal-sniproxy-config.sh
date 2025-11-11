#!/bin/bash
# Create a minimal working sniproxy config for testing
# Run: sudo bash create-minimal-sniproxy-config.sh

set -e

echo "Creating minimal sniproxy config for testing..."

# Backup current config
if [ -f /etc/sniproxy/sniproxy.conf ]; then
    sudo mv /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backed up old config"
fi

# Create minimal config with just a few domains to test
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
}

listen 0.0.0.0:443 {
    proto tls
    table {
        .netflix.com
        .disneyplus.com
        .hulu.com
    }
}

listen 0.0.0.0:80 {
    proto http
    table {
        .netflix.com
        .disneyplus.com
        .hulu.com
    }
}
EOF

echo "✅ Created minimal config with 3 domains"

# Test if it works
echo "Testing configuration..."
sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f &
TEST_PID=$!
sleep 2

if kill -0 $TEST_PID 2>/dev/null; then
    kill $TEST_PID 2>/dev/null || true
    echo "✅ Minimal config works! The issue is with the full config."
    echo "Now let's create the full config properly..."
    
    # Create full config
    sudo tee /etc/sniproxy/sniproxy.conf > /dev/null <<'FULLCONF'
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
FULLCONF
        
    echo "✅ Full config created"
else
    echo "❌ Even minimal config failed. Checking error:"
    wait $TEST_PID 2>/dev/null || true
    echo "Error details:"
    sudo journalctl -xeu sniproxy.service --no-pager | tail -10
    exit 1
fi

# Restart sniproxy
echo "Restarting sniproxy..."
sudo systemctl daemon-reload
sudo systemctl restart sniproxy

sleep 2

if sudo systemctl is-active --quiet sniproxy; then
    echo "✅ sniproxy is running!"
    sudo systemctl status sniproxy --no-pager -l | head -15
else
    echo "❌ sniproxy still failed. Error:"
    sudo journalctl -xeu sniproxy.service --no-pager | tail -10
    exit 1
fi

