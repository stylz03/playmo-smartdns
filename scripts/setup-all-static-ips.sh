#!/bin/bash
# Script to apply static US CDN IPs for all streaming services
# Run this on the EC2 instance via SSH: sudo bash setup-all-static-ips.sh
# Or use --zones-only flag to only create zone files without updating named.conf.local

set -e

ZONES_ONLY=false
if [ "$1" == "--zones-only" ]; then
    ZONES_ONLY=true
fi

echo "=========================================="
echo "Setting up static US CDN IPs for all streaming services"
echo "=========================================="
echo ""

# Create zones directory
mkdir -p /etc/bind/zones
echo "✅ Created /etc/bind/zones directory"

# Backup current config
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backed up named.conf.local"

# Function to create zone file
create_zone_file() {
    local domain=$1
    shift
    local ips=("$@")
    local zone_file="/etc/bind/zones/db.${domain//./_}"

    cat > "$zone_file" <<EOF
\$TTL    604800
@       IN      SOA     ns1.smartdns.local. admin.smartdns.local. (
                        2025111101         ; Serial
                        604800             ; Refresh
                        86400              ; Retry
                        2419200            ; Expire
                        604800 )           ; Negative Cache TTL
;
@       IN      NS      ns1.smartdns.local.
EOF

    for ip in "${ips[@]}"; do
        echo "@       IN      A       $ip" >> "$zone_file"
    done

    chmod 644 "$zone_file"
    echo "✅ Created zone file: $zone_file"
}

# Create zone files for all services with static IPs
echo ""
echo "Creating zone files..."

# Netflix
create_zone_file "netflix.com" "3.230.129.93" "52.3.144.142" "54.237.226.164"

# nflxvideo.net
create_zone_file "nflxvideo.net" "3.230.129.93" "52.3.144.142" "54.237.226.164"

# Disney+
create_zone_file "disneyplus.com" "34.110.155.89"

# bamgrid.com
create_zone_file "bamgrid.com" "34.110.155.89"

# Hulu
create_zone_file "hulu.com" "23.185.0.1" "23.185.0.2"

# HBO Max / Max
create_zone_file "hbomax.com" "52.85.124.14" "52.85.124.15"
create_zone_file "max.com" "52.85.124.14" "52.85.124.15"

# Peacock
create_zone_file "peacocktv.com" "23.185.0.1" "23.185.0.2"

# Paramount+
create_zone_file "paramountplus.com" "23.185.0.1" "23.185.0.2"
create_zone_file "paramount.com" "23.185.0.1" "23.185.0.2"

# ESPN
create_zone_file "espn.com" "23.185.0.1" "23.185.0.2"
create_zone_file "espnplus.com" "23.185.0.1" "23.185.0.2"

# Amazon Prime Video
create_zone_file "primevideo.com" "52.85.124.14" "52.85.124.15"
create_zone_file "amazonvideo.com" "52.85.124.14" "52.85.124.15"

# Apple TV
create_zone_file "tv.apple.com" "17.253.144.10" "17.253.144.11"

# Other services (using generic US CDN IPs)
for domain in "sling.com" "discoveryplus.com" "tubi.tv" "crackle.com" "roku.com" \
              "tntdrama.com" "tbs.com" "flosports.tv" "magellantv.com" "aetv.com" \
              "directv.com" "britbox.com" "dazn.com" "fubo.tv" "philo.com" \
              "dishanywhere.com" "xumo.tv" "hgtv.com" "amcplus.com" "mgmplus.com"; do
    create_zone_file "$domain" "23.185.0.1" "23.185.0.2"
done

# Update named.conf.local (skip if zones-only mode)
if [ "$ZONES_ONLY" == "true" ]; then
    echo ""
    echo "Zones-only mode: Skipping named.conf.local update"
    echo "Zone files created. named.conf.local should be updated separately."
    exit 0
fi

# Update named.conf.local
echo ""
echo "Updating named.conf.local..."

# Remove ALL existing zone definitions for streaming domains
# This removes both forwarding zones and any existing static zones
echo "Removing old zone definitions..."
for domain in "netflix.com" "nflxvideo.net" "disneyplus.com" "bamgrid.com" "hulu.com" \
              "hbomax.com" "max.com" "peacocktv.com" "paramountplus.com" "paramount.com" \
              "espn.com" "espnplus.com" "primevideo.com" "amazonvideo.com" "tv.apple.com" \
              "sling.com" "discoveryplus.com" "tubi.tv" "crackle.com" "roku.com" \
              "tntdrama.com" "tbs.com" "flosports.tv" "magellantv.com" "aetv.com" \
              "directv.com" "britbox.com" "dazn.com" "fubo.tv" "philo.com" \
              "dishanywhere.com" "xumo.tv" "hgtv.com" "amcplus.com" "mgmplus.com"; do
    # Remove zone block (from "zone" to closing "};")
    sed -i "/^zone \"${domain//./\\.}\" {/,/^};$/d" /etc/bind/named.conf.local
done

# Remove any leftover blank lines (more than 2 consecutive)
sed -i '/^$/N;/^\n$/d' /etc/bind/named.conf.local

# Remove old static zones comment block if it exists
sed -i '/# Static US CDN IP zones/,/^}$/d' /etc/bind/named.conf.local

# Add all static zones
cat >> /etc/bind/named.conf.local <<'EOF'

# Static US CDN IP zones
zone "netflix.com" {
    type master;
    file "/etc/bind/zones/db.netflix_com";
};

zone "nflxvideo.net" {
    type master;
    file "/etc/bind/zones/db.nflxvideo_net";
};

zone "disneyplus.com" {
    type master;
    file "/etc/bind/zones/db.disneyplus_com";
};

zone "bamgrid.com" {
    type master;
    file "/etc/bind/zones/db.bamgrid_com";
};

zone "hulu.com" {
    type master;
    file "/etc/bind/zones/db.hulu_com";
};

zone "hbomax.com" {
    type master;
    file "/etc/bind/zones/db.hbomax_com";
};

zone "max.com" {
    type master;
    file "/etc/bind/zones/db.max_com";
};

zone "peacocktv.com" {
    type master;
    file "/etc/bind/zones/db.peacocktv_com";
};

zone "paramountplus.com" {
    type master;
    file "/etc/bind/zones/db.paramountplus_com";
};

zone "paramount.com" {
    type master;
    file "/etc/bind/zones/db.paramount_com";
};

zone "espn.com" {
    type master;
    file "/etc/bind/zones/db.espn_com";
};

zone "espnplus.com" {
    type master;
    file "/etc/bind/zones/db.espnplus_com";
};

zone "primevideo.com" {
    type master;
    file "/etc/bind/zones/db.primevideo_com";
};

zone "amazonvideo.com" {
    type master;
    file "/etc/bind/zones/db.amazonvideo_com";
};

zone "tv.apple.com" {
    type master;
    file "/etc/bind/zones/db.tv_apple_com";
};

zone "sling.com" {
    type master;
    file "/etc/bind/zones/db.sling_com";
};

zone "discoveryplus.com" {
    type master;
    file "/etc/bind/zones/db.discoveryplus_com";
};

zone "tubi.tv" {
    type master;
    file "/etc/bind/zones/db.tubi_tv";
};

zone "crackle.com" {
    type master;
    file "/etc/bind/zones/db.crackle_com";
};

zone "roku.com" {
    type master;
    file "/etc/bind/zones/db.roku_com";
};

zone "tntdrama.com" {
    type master;
    file "/etc/bind/zones/db.tntdrama_com";
};

zone "tbs.com" {
    type master;
    file "/etc/bind/zones/db.tbs_com";
};

zone "flosports.tv" {
    type master;
    file "/etc/bind/zones/db.flosports_tv";
};

zone "magellantv.com" {
    type master;
    file "/etc/bind/zones/db.magellantv_com";
};

zone "aetv.com" {
    type master;
    file "/etc/bind/zones/db.aetv_com";
};

zone "directv.com" {
    type master;
    file "/etc/bind/zones/db.directv_com";
};

zone "britbox.com" {
    type master;
    file "/etc/bind/zones/db.britbox_com";
};

zone "dazn.com" {
    type master;
    file "/etc/bind/zones/db.dazn_com";
};

zone "fubo.tv" {
    type master;
    file "/etc/bind/zones/db.fubo_tv";
};

zone "philo.com" {
    type master;
    file "/etc/bind/zones/db.philo_com";
};

zone "dishanywhere.com" {
    type master;
    file "/etc/bind/zones/db.dishanywhere_com";
};

zone "xumo.tv" {
    type master;
    file "/etc/bind/zones/db.xumo_tv";
};

zone "hgtv.com" {
    type master;
    file "/etc/bind/zones/db.hgtv_com";
};

zone "amcplus.com" {
    type master;
    file "/etc/bind/zones/db.amcplus_com";
};

zone "mgmplus.com" {
    type master;
    file "/etc/bind/zones/db.mgmplus_com";
};
EOF

# Validate configuration
echo ""
echo "Validating configuration..."
if named-checkconf; then
    echo "✅ named.conf is valid"
else
    echo "❌ named.conf validation failed!"
    exit 1
fi

# Validate zone files
echo "Validating zone files..."
for zone_file in /etc/bind/zones/db.*; do
    if [ -f "$zone_file" ]; then
        domain=$(basename "$zone_file" | sed 's/db\.//' | sed 's/_/./g')
        if named-checkzone "$domain" "$zone_file" >/dev/null 2>&1; then
            echo "✅ Zone $domain is valid"
        else
            echo "⚠️  Zone $domain validation failed (continuing...)"
        fi
    fi
done

# Restart BIND9
echo ""
echo "Restarting BIND9..."
systemctl restart bind9

# Check status
if systemctl is-active --quiet bind9; then
    echo "✅ BIND9 is running"
    echo ""
    echo "=========================================="
    echo "✅ Setup complete!"
    echo "=========================================="
    echo ""
    echo "Test with:"
    echo "  dig @3.151.46.11 netflix.com +short"
    echo "  dig @3.151.46.11 disneyplus.com +short"
    echo "  dig @3.151.46.11 hulu.com +short"
    echo ""
    systemctl status bind9 --no-pager | head -10
else
    echo "❌ BIND9 failed to start!"
    echo "Restoring backup..."
    cp /etc/bind/named.conf.local.backup.* /etc/bind/named.conf.local
    systemctl restart bind9
    exit 1
fi

