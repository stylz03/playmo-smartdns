#!/bin/bash
# Configure BIND9 to use ControlD DNS servers
# Usage: ./configure-controld-dns.sh <controld-primary-dns> [controld-secondary-dns]

set -e

CONTROLD_PRIMARY="${1:-}"
CONTROLD_SECONDARY="${2:-76.76.21.21}"

if [ -z "$CONTROLD_PRIMARY" ]; then
    echo "Usage: $0 <controld-primary-dns> [controld-secondary-dns]"
    echo "Example: $0 76.76.19.19 76.76.21.21"
    echo ""
    echo "Or use your custom ControlD DNS endpoint"
    exit 1
fi

echo "=========================================="
echo "Configuring BIND9 to use ControlD DNS"
echo "=========================================="

# Backup current config
if [ -f /etc/bind/named.conf.options ]; then
    cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backed up current config"
fi

# Update BIND9 to forward to ControlD DNS
cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
    query-source address *;
    
    # Forward to ControlD DNS servers
    forwarders {
        $CONTROLD_PRIMARY;   // ControlD Primary DNS
        $CONTROLD_SECONDARY; // ControlD Secondary DNS
    };
    forward only;
};
EOF

# Validate configuration
if named-checkconf; then
    echo "✅ BIND9 configuration is valid"
    echo ""
    echo "Restarting BIND9..."
    systemctl restart bind9
    
    if systemctl is-active --quiet bind9; then
        echo "✅ BIND9 restarted successfully"
        echo ""
        echo "BIND9 is now forwarding to ControlD DNS:"
        echo "  Primary: $CONTROLD_PRIMARY"
        echo "  Secondary: $CONTROLD_SECONDARY"
        echo ""
        echo "Test with:"
        echo "  dig @localhost netflix.com"
        echo "  dig @localhost disneyplus.com"
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

