#!/bin/bash
# Fix missing zone files for sniproxy setup
# Run: sudo bash fix-missing-zone-files.sh

set -e

echo "=========================================="
echo "Creating missing zone files"
echo "=========================================="

# Get EC2 public IP
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "3.151.46.11")
echo "Using EC2 IP: $EC2_IP"

# Ensure zones directory exists
mkdir -p /etc/bind/zones
echo "✅ Zones directory ready"

# List of streaming domains (from services.json or hardcoded)
DOMAINS=(
    "netflix.com" "nflxvideo.net" "hulu.com" "disneyplus.com" "bamgrid.com"
    "hbomax.com" "max.com" "peacocktv.com" "paramountplus.com" "paramount.com"
    "espn.com" "espnplus.com" "primevideo.com" "amazonvideo.com" "tv.apple.com"
    "sling.com" "discoveryplus.com" "tubi.tv" "crackle.com" "roku.com"
    "tntdrama.com" "tbs.com" "flosports.tv" "magellantv.com" "aetv.com"
    "directv.com" "britbox.com" "dazn.com" "fubo.tv" "philo.com"
    "dishanywhere.com" "xumo.tv" "hgtv.com" "amcplus.com" "mgmplus.com"
)

# Function to create zone file
create_zone_file() {
    local domain=$1
    local ip=$2
    local zone_file="/etc/bind/zones/db.${domain//./_}"

    echo "Creating zone file: $zone_file for $domain -> $ip"
    
    cat > "$zone_file" <<EOF
\$TTL    604800
@       IN      SOA     ns1.smartdns.local. admin.smartdns.local. (
                        $(date +%Y%m%d%H)         ; Serial
                        604800             ; Refresh
                        86400              ; Retry
                        2419200            ; Expire
                        604800 )           ; Negative Cache TTL
;
@       IN      NS      ns1.smartdns.local.
@       IN      A       $ip
www     IN      A       $ip
*       IN      A       $ip
EOF
    
    chmod 644 "$zone_file"
    echo "✅ Created: $zone_file"
}

# Create zone files for all domains
echo ""
echo "Creating zone files..."
for domain in "${DOMAINS[@]}"; do
    create_zone_file "$domain" "$EC2_IP"
done

echo ""
echo "✅ Created $(ls -1 /etc/bind/zones/* 2>/dev/null | wc -l) zone files"

# Validate zone files
echo ""
echo "Validating zone files..."
for domain in "${DOMAINS[@]}"; do
    zone_file="/etc/bind/zones/db.${domain//./_}"
    if [ -f "$zone_file" ]; then
        if named-checkzone "$domain" "$zone_file" >/dev/null 2>&1; then
            echo "✅ $domain zone is valid"
        else
            echo "❌ $domain zone has errors"
            named-checkzone "$domain" "$zone_file" || true
        fi
    fi
done

# Reload BIND9
echo ""
echo "Reloading BIND9..."
systemctl reload bind9 || systemctl restart bind9
sleep 2

# Test DNS
echo ""
echo "Testing DNS resolution..."
echo "Testing netflix.com:"
dig @127.0.0.1 netflix.com +short || echo "❌ Failed"
echo ""
echo "Testing disneyplus.com:"
dig @127.0.0.1 disneyplus.com +short || echo "❌ Failed"
echo ""
echo "Testing from external (EC2 IP):"
dig @$EC2_IP netflix.com +short || echo "❌ Failed"

echo ""
echo "=========================================="
echo "✅ Zone files created and BIND9 reloaded"
echo "=========================================="
echo ""
echo "Zone files created: $(ls -1 /etc/bind/zones/* 2>/dev/null | wc -l)"
echo "All domains should now resolve to: $EC2_IP"

