#!/bin/bash
# Fix sniproxy with wildcard domains for all subdomains
# Run: sudo bash fix-sniproxy-wildcards.sh

set -e

echo "=========================================="
echo "Fixing Sniproxy with Wildcard Domains"
echo "=========================================="

# Stop sniproxy
systemctl stop sniproxy 2>/dev/null || true

# Backup
cp /etc/sniproxy/sniproxy.conf /etc/sniproxy/sniproxy.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Create config with wildcards for all subdomains
python3 << 'PYTHON_CONFIG'
config = """user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

# Table with wildcards to catch all subdomains
table {
    .netflix.com
    .nflxvideo.net
    .nflximg.net
    .nflxext.com
    .nflxso.net
    .disneyplus.com
    .bamgrid.com
    .dssott.com
    .disney.com
    .disneystreaming.com
    .hulu.com
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
        .nflxvideo.net
        .nflximg.net
        .nflxext.com
        .nflxso.net
        .disneyplus.com
        .bamgrid.com
        .dssott.com
        .disney.com
        .disneystreaming.com
        .hulu.com
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
        .nflxvideo.net
        .nflximg.net
        .nflxext.com
        .nflxso.net
        .disneyplus.com
        .bamgrid.com
        .dssott.com
        .disney.com
        .disneystreaming.com
        .hulu.com
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
print("✅ Config created with expanded domain list (including subdomains)")
PYTHON_CONFIG

# Restart sniproxy
echo ""
echo "Restarting sniproxy..."
systemctl daemon-reload
systemctl restart sniproxy
sleep 3

if systemctl is-active --quiet sniproxy; then
    echo "✅ Sniproxy restarted"
    systemctl status sniproxy --no-pager -l | head -10
else
    echo "❌ Sniproxy failed to start"
    journalctl -xeu sniproxy.service --no-pager | tail -20
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Sniproxy updated with expanded domains"
echo "=========================================="
echo ""
echo "Note: Sniproxy only handles TCP/TLS (port 443)."
echo "Streaming apps also use QUIC/HTTP3 (UDP) which sniproxy can't handle."
echo ""
echo "For full support, we may need to add nginx stream proxy for UDP/QUIC."

