#!/bin/bash
# Quick fix script to remove old forwarding zones and add static zones
# Run this on EC2 after the script failed

set -e

echo "Fixing named.conf.local..."

# Restore backup first
if [ -f /etc/bind/named.conf.local.backup.* ]; then
    cp /etc/bind/named.conf.local.backup.* /etc/bind/named.conf.local
    echo "✅ Restored backup"
fi

# Remove all existing zone definitions for streaming domains
echo "Removing old zone definitions..."
for domain in "netflix.com" "nflxvideo.net" "disneyplus.com" "bamgrid.com" "hulu.com" \
              "hbomax.com" "max.com" "peacocktv.com" "paramountplus.com" "paramount.com" \
              "espn.com" "espnplus.com" "primevideo.com" "amazonvideo.com" "tv.apple.com" \
              "sling.com" "discoveryplus.com" "tubi.tv" "crackle.com" "roku.com" \
              "tntdrama.com" "tbs.com" "flosports.tv" "magellantv.com" "aetv.com" \
              "directv.com" "britbox.com" "dazn.com" "fubo.tv" "philo.com" \
              "dishanywhere.com" "xumo.tv" "hgtv.com" "amcplus.com" "mgmplus.com"; do
    # Escape dots for sed
    escaped_domain=$(echo "$domain" | sed 's/\./\\./g')
    # Remove zone block
    sed -i "/^zone \"${escaped_domain}\" {/,/^};$/d" /etc/bind/named.conf.local
done

# Clean up extra blank lines
sed -i '/^$/N;/^\n$/d' /etc/bind/named.conf.local

# Add static zones
echo "Adding static zone definitions..."
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

# Validate
if named-checkconf; then
    echo "✅ Configuration is valid"
    systemctl restart bind9
    echo "✅ BIND9 restarted"
    echo ""
    echo "Test with: dig @3.151.46.11 netflix.com +short"
else
    echo "❌ Configuration error!"
    exit 1
fi

