#!/bin/bash
# Disable zone files when using ControlD
# Zone files force domains to resolve to EC2 IP, which overrides ControlD
# This script removes/backs up zone files and zone configs

set -e

echo "=========================================="
echo "Disabling Zone Files for ControlD"
echo "=========================================="
echo ""
echo "Zone files force streaming domains to resolve to EC2 IP,"
echo "which prevents ControlD from handling geo-unblocking."
echo ""

# Backup named.conf.local
if [ -f /etc/bind/named.conf.local ]; then
    cp /etc/bind/named.conf.local /etc/bind/named.conf.local.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backed up named.conf.local"
fi

# Remove zone definitions from named.conf.local
echo "Removing zone definitions from named.conf.local..."
# Create empty named.conf.local (or keep only non-streaming zones)
cat > /etc/bind/named.conf.local <<EOF
// Zone files disabled - using ControlD for geo-unblocking
// All DNS queries will be forwarded to ControlD
// Original config backed up as: named.conf.local.backup.*
EOF

# Backup zone files (don't delete, just in case)
if [ -d /etc/bind/zones ]; then
    if [ "$(ls -A /etc/bind/zones)" ]; then
        mkdir -p /etc/bind/zones.backup.$(date +%Y%m%d_%H%M%S)
        mv /etc/bind/zones/* /etc/bind/zones.backup.$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
        echo "✅ Backed up zone files to /etc/bind/zones.backup.*"
    fi
fi

# Validate and restart BIND9
echo ""
echo "Validating BIND9 configuration..."
if named-checkconf; then
    echo "✅ BIND9 configuration is valid"
    echo ""
    echo "Restarting BIND9..."
    systemctl restart bind9
    
    if systemctl is-active --quiet bind9; then
        echo "✅ BIND9 restarted successfully"
        echo ""
        echo "Now all DNS queries will be forwarded to ControlD!"
        echo ""
        echo "Test with:"
        echo "  dig @127.0.0.1 netflix.com"
        echo "  dig @127.0.0.1 disneyplus.com"
    else
        echo "❌ BIND9 failed to start"
        systemctl status bind9
        exit 1
    fi
else
    echo "❌ BIND9 configuration is invalid"
    named-checkconf
    exit 1
fi

