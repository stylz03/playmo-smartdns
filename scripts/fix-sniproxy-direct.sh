#!/bin/bash
# Direct fix for sniproxy - fixes corruption and recreates config
# Run: sudo bash fix-sniproxy-direct.sh

set -e

echo "=========================================="
echo "Direct sniproxy config fix"
echo "=========================================="

# Backup
if [ -f /etc/sniproxy/sniproxy.conf ]; then
    sudo cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S)
fi

# First, try to fix any "roto" -> "proto" corruption
echo "Fixing any 'roto' -> 'proto' corruption..."
sudo sed -i 's/roto tls/proto tls/g' /etc/sniproxy/sniproxy.conf 2>/dev/null || true
sudo sed -i 's/roto http/proto http/g' /etc/sniproxy/sniproxy.conf 2>/dev/null || true

# Remove CRLF
echo "Converting line endings..."
sudo sed -i 's/\r$//' /etc/sniproxy/sniproxy.conf

# Now completely recreate the file using printf to avoid any heredoc issues
echo "Recreating config file..."

sudo rm -f /etc/sniproxy/sniproxy.conf

# Write config line by line to avoid any encoding issues
sudo bash << 'WRITECONFIG'
cat > /etc/sniproxy/sniproxy.conf << 'EOF'
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
WRITECONFIG

# Set permissions
sudo chmod 644 /etc/sniproxy/sniproxy.conf
sudo chown root:root /etc/sniproxy/sniproxy.conf

# Verify
echo ""
echo "Verifying config..."
# Check for actual corruption: "roto" that is NOT part of "proto"
# This checks for "roto" that is not preceded by "p"
if grep -qE "[^p]roto[[:space:]]" /etc/sniproxy/sniproxy.conf || grep -qE "^roto[[:space:]]" /etc/sniproxy/sniproxy.conf; then
    echo "❌ ERROR: Found corrupted 'roto' (not 'proto') in config!"
    echo "File content around corrupted 'roto':"
    grep -nE "[^p]roto[[:space:]]|^roto[[:space:]]" /etc/sniproxy/sniproxy.conf || true
    exit 1
fi

if ! grep -q "proto tls" /etc/sniproxy/sniproxy.conf; then
    echo "❌ ERROR: 'proto tls' not found!"
    exit 1
fi

if ! grep -q "proto http" /etc/sniproxy/sniproxy.conf; then
    echo "❌ ERROR: 'proto http' not found!"
    exit 1
fi

echo "✅ Config file verified clean"
echo "Lines: $(wc -l < /etc/sniproxy/sniproxy.conf)"
echo "File size: $(wc -c < /etc/sniproxy/sniproxy.conf) bytes"

# Show a sample to confirm
echo ""
echo "Sample of config (around 'proto tls'):"
grep -A 3 -B 1 "proto tls" /etc/sniproxy/sniproxy.conf | head -5

# Test
echo ""
echo "Testing config..."
TEST_OUTPUT=$(timeout 3 sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 || true)
if echo "$TEST_OUTPUT" | grep -q "Unable to load\|error parsing"; then
    echo "❌ Config test failed:"
    echo "$TEST_OUTPUT"
    echo ""
    echo "Checking file encoding:"
    file /etc/sniproxy/sniproxy.conf
    echo ""
    echo "First 20 bytes (hex):"
    head -c 20 /etc/sniproxy/sniproxy.conf | od -An -tx1
    exit 1
fi

# Restart
echo ""
echo "Restarting sniproxy..."
sudo systemctl daemon-reload
sudo systemctl restart sniproxy

sleep 3

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
    sudo journalctl -xeu sniproxy.service --no-pager | tail -15
    exit 1
fi

