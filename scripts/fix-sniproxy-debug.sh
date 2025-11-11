#!/bin/bash
# Debug and fix sniproxy config
# Run: sudo bash fix-sniproxy-debug.sh

set -e

echo "=========================================="
echo "Debugging Sniproxy Config"
echo "=========================================="

# Stop sniproxy
systemctl stop sniproxy 2>/dev/null || true

# Check current config
echo "1. Current config file:"
if [ -f /etc/sniproxy/sniproxy.conf ]; then
    echo "✅ Config exists"
    echo "File size: $(wc -l < /etc/sniproxy/sniproxy.conf) lines"
    echo ""
    echo "First 20 lines:"
    head -20 /etc/sniproxy/sniproxy.conf
    echo ""
    echo "Last 20 lines:"
    tail -20 /etc/sniproxy/sniproxy.conf
else
    echo "❌ Config file missing"
fi

# Try to get detailed error
echo ""
echo "2. Testing config with sniproxy (showing full error):"
/usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 | head -30 || true

# Check for duplicate table definitions
echo ""
echo "3. Checking for duplicate table definitions:"
TABLE_COUNT=$(grep -c "^table {" /etc/sniproxy/sniproxy.conf || echo "0")
echo "Found $TABLE_COUNT 'table {' definitions"

if [ "$TABLE_COUNT" -gt 1 ]; then
    echo "❌ Multiple table definitions found - this is the problem!"
    echo "Table definitions at lines:"
    grep -n "^table {" /etc/sniproxy/sniproxy.conf
fi

# Check for syntax issues
echo ""
echo "4. Checking brace matching:"
OPEN_BRACES=$(grep -o '{' /etc/sniproxy/sniproxy.conf | wc -l)
CLOSE_BRACES=$(grep -o '}' /etc/sniproxy/sniproxy.conf | wc -l)
echo "Open braces: $OPEN_BRACES"
echo "Close braces: $CLOSE_BRACES"

if [ "$OPEN_BRACES" != "$CLOSE_BRACES" ]; then
    echo "❌ Unmatched braces!"
fi

# Create a clean, minimal config to test
echo ""
echo "5. Creating clean minimal config for testing..."
cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S)

python3 << 'PYTHON_CONFIG'
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
"""
with open('/etc/sniproxy/sniproxy.conf', 'w') as f:
    f.write(config)
print("✅ Created minimal test config (3 domains)")
PYTHON_CONFIG

# Test minimal config
echo ""
echo "6. Testing minimal config..."
if timeout 3 /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 | head -5; then
    echo "✅ Minimal config works!"
    echo ""
    echo "Now creating full config..."
    
    # Create full config
    python3 << 'PYTHON_CONFIG2'
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
print("✅ Full config created")
PYTHON_CONFIG2
    
    # Test full config
    if timeout 3 /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 | head -5; then
        echo "✅ Full config works!"
    else
        FULL_ERROR=$(timeout 3 /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 || true)
        if echo "$FULL_ERROR" | grep -q "Unable to load\|error parsing"; then
            echo "❌ Full config failed:"
            echo "$FULL_ERROR"
            echo ""
            echo "Restoring minimal config..."
            python3 << 'PYTHON_MINIMAL'
config = """user daemon
pidfile /var/run/sniproxy.pid
error_log { syslog daemon priority notice }
table { .netflix.com .disneyplus.com .hulu.com }
listen 0.0.0.0:443 { proto tls table { .netflix.com .disneyplus.com .hulu.com } }
listen 0.0.0.0:80 { proto http table { .netflix.com .disneyplus.com .hulu.com } }
"""
with open('/etc/sniproxy/sniproxy.conf', 'w') as f:
    f.write(config)
print("✅ Restored minimal working config")
PYTHON_MINIMAL
        fi
    fi
else
    MIN_ERROR=$(timeout 3 /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 || true)
    echo "❌ Even minimal config failed:"
    echo "$MIN_ERROR"
    exit 1
fi

# Restart sniproxy
echo ""
echo "7. Restarting sniproxy..."
systemctl daemon-reload
systemctl restart sniproxy
sleep 3

if systemctl is-active --quiet sniproxy; then
    echo "✅ Sniproxy is running!"
    systemctl status sniproxy --no-pager -l | head -15
else
    echo "❌ Sniproxy failed to start"
    journalctl -xeu sniproxy.service --no-pager | tail -20
    exit 1
fi

