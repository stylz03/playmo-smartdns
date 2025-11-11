#!/bin/bash
# Script to update BIND9 configuration on existing EC2 instance
# Run this on the EC2 instance via SSH

set -e

echo "Updating BIND9 configuration for US-based SmartDNS..."

# Backup current config
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup.$(date +%Y%m%d_%H%M%S)

# Update named.conf.options with optimized US-based configuration
cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
    # Ensure queries use the EC2's public IP (US-based)
    # This makes upstream DNS resolvers see queries from US location
    query-source address * port 53;
    # No global forwarders - streaming domains use zone-specific forwarding
    # Non-streaming domains use normal recursive resolution
};
EOF

# Validate configuration
if named-checkconf; then
    echo "✅ Configuration is valid"
    # Restart BIND9
    systemctl restart bind9
    echo "✅ BIND9 restarted with new configuration"
    systemctl status bind9 --no-pager | head -10
else
    echo "❌ Configuration error! Restoring backup..."
    cp /etc/bind/named.conf.options.backup.* /etc/bind/named.conf.options
    systemctl restart bind9
    exit 1
fi

echo ""
echo "✅ BIND9 configuration updated successfully!"
echo "The DNS server will now ensure queries appear from US location."

