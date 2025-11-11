#!/bin/bash
# Script to manually apply static US CDN IPs on EC2
# Run this on the EC2 instance via SSH

set -e

echo "Applying static US CDN IPs configuration..."

# Create zones directory
mkdir -p /etc/bind/zones

# Create zone files for major streaming services
# Netflix
cat > /etc/bind/zones/db.netflix_com <<'EOF'
$TTL    604800
@       IN      SOA     ns1.smartdns.local. admin.smartdns.local. (
                        2025111101         ; Serial
                        604800             ; Refresh
                        86400              ; Retry
                        2419200            ; Expire
                        604800 )           ; Negative Cache TTL
;
@       IN      NS      ns1.smartdns.local.
@       IN      A       3.230.129.93
@       IN      A       52.3.144.142
@       IN      A       54.237.226.164
EOF

# Disney+
cat > /etc/bind/zones/db.disneyplus_com <<'EOF'
$TTL    604800
@       IN      SOA     ns1.smartdns.local. admin.smartdns.local. (
                        2025111101         ; Serial
                        604800             ; Refresh
                        86400              ; Retry
                        2419200            ; Expire
                        604800 )           ; Negative Cache TTL
;
@       IN      NS      ns1.smartdns.local.
@       IN      A       34.110.155.89
EOF

# Update named.conf.local to use static zones
# Backup first
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.backup.$(date +%Y%m%d_%H%M%S)

# Add static zones (append to existing config)
cat >> /etc/bind/named.conf.local <<'EOF'

# Static US CDN IP zones
zone "netflix.com" {
    type master;
    file "/etc/bind/zones/db.netflix_com";
};

zone "disneyplus.com" {
    type master;
    file "/etc/bind/zones/db.disneyplus_com";
};
EOF

# Validate and restart
if named-checkconf && named-checkzone netflix.com /etc/bind/zones/db.netflix_com && named-checkzone disneyplus.com /etc/bind/zones/db.disneyplus_com; then
    systemctl restart bind9
    echo "✅ BIND9 restarted with static US CDN IPs"
    systemctl status bind9 --no-pager | head -10
else
    echo "❌ Configuration error! Restoring backup..."
    cp /etc/bind/named.conf.local.backup.* /etc/bind/named.conf.local
    systemctl restart bind9
    exit 1
fi

echo ""
echo "✅ Static US CDN IPs applied!"
echo "Test with: dig @3.151.46.11 netflix.com +short"

