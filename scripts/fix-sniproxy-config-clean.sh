#!/bin/bash
# Clean fix for sniproxy config - removes all hidden characters and recreates
# Run: sudo bash fix-sniproxy-config-clean.sh

set -e

echo "=========================================="
echo "Fixing sniproxy config (clean method)"
echo "=========================================="

# Backup old config
if [ -f /etc/sniproxy/sniproxy.conf ]; then
    sudo mv /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backed up old config"
fi

# Check for corrupted content
echo "Checking for corrupted content in backup..."
if [ -f /etc/sniproxy/sniproxy.conf.backup.* ]; then
    BACKUP_FILE=$(ls -t /etc/sniproxy/sniproxy.conf.backup.* | head -1)
    echo "Checking backup file: $BACKUP_FILE"
    if grep -q "roto tls" "$BACKUP_FILE" 2>/dev/null; then
        echo "⚠️ Found 'roto tls' corruption in backup"
    fi
    if file "$BACKUP_FILE" | grep -q "CRLF"; then
        echo "⚠️ Backup file has CRLF line endings (Windows format)"
    fi
fi

# Create config file using printf to avoid any encoding issues
echo "Creating clean config file..."

sudo bash -c 'cat > /etc/sniproxy/sniproxy.conf << '\''ENDOFFILE'\''
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
ENDOFFILE'

# Convert to Unix line endings (remove CRLF if present)
sudo dos2unix /etc/sniproxy/sniproxy.conf 2>/dev/null || sudo sed -i 's/\r$//' /etc/sniproxy/sniproxy.conf

# Set correct permissions
sudo chmod 644 /etc/sniproxy/sniproxy.conf
sudo chown root:root /etc/sniproxy/sniproxy.conf

# Verify file is clean
echo ""
echo "Verifying config file..."
if grep -q "roto tls" /etc/sniproxy/sniproxy.conf; then
    echo "❌ ERROR: Still found 'roto tls' in config!"
    exit 1
fi

if ! grep -q "proto tls" /etc/sniproxy/sniproxy.conf; then
    echo "❌ ERROR: 'proto tls' not found in config!"
    exit 1
fi

echo "✅ Config file is clean (no corruption detected)"
echo "File size: $(wc -l < /etc/sniproxy/sniproxy.conf) lines"

# Test config manually first
echo ""
echo "Testing config manually..."
if timeout 2 sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 | head -5; then
    echo "⚠️ Config test output shown above"
else
    TEST_OUTPUT=$(timeout 2 sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 || true)
    if echo "$TEST_OUTPUT" | grep -q "Unable to load\|error parsing"; then
        echo "❌ Config still has errors:"
        echo "$TEST_OUTPUT"
        exit 1
    fi
fi

# Restart sniproxy
echo ""
echo "Restarting sniproxy..."
sudo systemctl daemon-reload
sudo systemctl restart sniproxy

sleep 3

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
    echo "Config file check (around 'proto tls'):"
    grep -A 2 -B 2 "proto tls" /etc/sniproxy/sniproxy.conf | head -10
    exit 1
fi

