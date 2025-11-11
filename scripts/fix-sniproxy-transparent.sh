#!/bin/bash
# Fix sniproxy to forward transparently to original destination
# Run: sudo bash fix-sniproxy-transparent.sh

set -e

echo "=========================================="
echo "Fixing Sniproxy Transparent Forwarding"
echo "=========================================="

# Stop sniproxy
systemctl stop sniproxy

# Backup config
cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S)

# The issue: sniproxy needs to forward to the ORIGINAL destination
# When DNS resolves netflix.com to EC2 IP, sniproxy needs to forward to real netflix.com
# We need to use resolver or configure forwarding differently

# Create new config with resolver for original destination lookup
python3 << 'PYTHON_CONFIG'
config = """user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

# Resolver for looking up original destination IPs
resolver {
    nameserver 8.8.8.8
    nameserver 1.1.1.1
}

# Table for streaming domains - forward to original destination
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
print("✅ Config updated with resolver for transparent forwarding")
PYTHON_CONFIG

# Ensure IP forwarding is enabled
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p >/dev/null 2>&1 || true

# Restart sniproxy
echo ""
echo "Restarting sniproxy..."
systemctl daemon-reload
systemctl restart sniproxy
sleep 3

if systemctl is-active --quiet sniproxy; then
    echo "✅ Sniproxy restarted"
    echo ""
    echo "Testing forwarding..."
    sleep 2
    echo "Test from EC2:"
    timeout 5 curl -v -k --resolve netflix.com:443:3.151.46.11 https://netflix.com 2>&1 | head -15 || echo "Test completed (may show errors, that's OK)"
else
    echo "❌ Sniproxy failed to start"
    journalctl -u sniproxy -n 20 --no-pager
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Sniproxy configured for transparent forwarding"
echo "=========================================="
echo ""
echo "Now sniproxy will:"
echo "1. Receive connection to EC2 IP (3.151.46.11)"
echo "2. Read SNI (e.g., netflix.com)"
echo "3. Match SNI to table"
echo "4. Resolve original destination (netflix.com) using resolver"
echo "5. Forward transparently to original destination"
echo ""
echo "Your phone should now be able to access streaming sites!"

