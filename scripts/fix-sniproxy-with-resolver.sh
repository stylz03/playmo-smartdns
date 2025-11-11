#!/bin/bash
# Fix sniproxy with resolver for original destination lookup
# Run: sudo bash fix-sniproxy-with-resolver.sh

set -e

echo "=========================================="
echo "Fixing Sniproxy with Resolver"
echo "=========================================="

# Stop sniproxy
systemctl stop sniproxy 2>/dev/null || true

# Backup
cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Sniproxy needs to resolve the original destination when forwarding
# When client connects to EC2 IP with SNI "netflix.com", sniproxy needs
# to resolve "netflix.com" to its real IP to forward to

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
print("✅ Config created with resolver and inline tables")
PYTHON_CONFIG

# Test config
echo ""
echo "Testing config..."
/usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f &
SNIPROXY_PID=$!
sleep 3

if kill -0 $SNIPROXY_PID 2>/dev/null; then
    echo "✅ Sniproxy started (PID: $SNIPROXY_PID)"
    kill $SNIPROXY_PID 2>/dev/null || true
    sleep 1
else
    echo "❌ Sniproxy failed to start"
    wait $SNIPROXY_PID 2>&1 || true
    echo ""
    echo "Trying without resolver (sniproxy might resolve automatically)..."
    # Try without resolver
    python3 << 'PYTHON_CONFIG2'
config = """user daemon
pidfile /var/run/sniproxy.pid
error_log { syslog daemon priority notice }
table { .netflix.com .disneyplus.com .hulu.com }
listen 0.0.0.0:443 { proto tls table { .netflix.com .disneyplus.com .hulu.com } }
listen 0.0.0.0:80 { proto http table { .netflix.com .disneyplus.com .hulu.com } }
"""
with open('/etc/sniproxy/sniproxy.conf', 'w') as f:
    f.write(config)
print("✅ Created minimal config without resolver")
PYTHON_CONFIG2
    
    /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f &
    SNIPROXY_PID2=$!
    sleep 3
    if kill -0 $SNIPROXY_PID2 2>/dev/null; then
        echo "✅ Minimal config works - creating full config..."
        # Create full config without resolver
        python3 << 'PYTHON_CONFIG3'
config = """user daemon
pidfile /var/run/sniproxy.pid
error_log { syslog daemon priority notice }
table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com }
listen 0.0.0.0:443 { proto tls table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com } }
listen 0.0.0.0:80 { proto http table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com } }
"""
with open('/etc/sniproxy/sniproxy.conf', 'w') as f:
    f.write(config)
print("✅ Full config created (single-line format)")
PYTHON_CONFIG3
        kill $SNIPROXY_PID2 2>/dev/null || true
    else
        echo "❌ Even minimal config failed"
        wait $SNIPROXY_PID2 2>&1 || true
        exit 1
    fi
fi

# Ensure IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p >/dev/null 2>&1 || true

# Restart service
echo ""
echo "Restarting sniproxy service..."
systemctl daemon-reload
systemctl restart sniproxy
sleep 4

if systemctl is-active --quiet sniproxy; then
    echo ""
    echo "=========================================="
    echo "✅ SNIPROXY IS RUNNING!"
    echo "=========================================="
    systemctl status sniproxy --no-pager -l | head -15
else
    echo ""
    echo "=========================================="
    echo "❌ SNIPROXY FAILED TO START"
    echo "=========================================="
    journalctl -xeu sniproxy.service --no-pager | tail -20
    exit 1
fi

