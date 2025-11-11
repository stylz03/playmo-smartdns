#!/bin/bash
# Clear BIND9 cache to ensure fresh DNS lookups from ControlD

set -e

echo "=========================================="
echo "Clearing BIND9 Cache"
echo "=========================================="

# Stop BIND9
echo "Stopping BIND9..."
systemctl stop bind9

# Clear cache directory
if [ -d /var/cache/bind ]; then
    echo "Clearing cache directory..."
    rm -rf /var/cache/bind/*
    echo "✅ Cache cleared"
fi

# Clear any other cache locations
if [ -d /var/lib/bind ]; then
    echo "Clearing bind directory..."
    find /var/lib/bind -type f -name "*.jnl" -delete 2>/dev/null || true
    find /var/lib/bind -type f -name "*.jbk" -delete 2>/dev/null || true
fi

# Start BIND9
echo "Starting BIND9..."
systemctl start bind9

if systemctl is-active --quiet bind9; then
    echo "✅ BIND9 restarted with cleared cache"
    echo ""
    echo "Test DNS resolution:"
    echo "  dig @127.0.0.1 netflix.com"
    echo "  dig @127.0.0.1 disneyplus.com"
else
    echo "❌ BIND9 failed to start"
    systemctl status bind9
    exit 1
fi

