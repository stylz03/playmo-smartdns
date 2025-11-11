#!/bin/bash
# Create zone files for streaming domains with static US CDN IPs
# Run this on EC2: sudo bash create-zone-files-now.sh

set -e

echo "=== Creating Zone Files for Streaming Domains ==="

# Zone files directory
ZONES_DIR="/etc/bind/zones"
mkdir -p "$ZONES_DIR"

# Create zone files for domains with static US CDN IPs
create_zone_file() {
    local domain=$1
    shift
    local ips=("$@")
    local zone_file="$ZONES_DIR/db.${domain//./_}"
    
    echo "Creating zone file: $zone_file"
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
$(for ip in "${ips[@]}"; do echo "@       IN      A       $ip"; done)
EOF
    chown root:bind "$zone_file"
    chmod 644 "$zone_file"
    echo "✅ Created: $zone_file"
}

# Netflix
create_zone_file "netflix.com" "3.230.129.93" "52.3.144.142" "54.237.226.164"
create_zone_file "nflxvideo.net" "3.230.129.93" "52.3.144.142" "54.237.226.164"

# Disney+
create_zone_file "disneyplus.com" "34.110.155.89"
create_zone_file "bamgrid.com" "34.110.155.89"

# Hulu
create_zone_file "hulu.com" "23.185.0.1" "23.185.0.2"

# HBO Max
create_zone_file "hbomax.com" "52.85.124.14" "52.85.124.15"
create_zone_file "max.com" "52.85.124.14" "52.85.124.15"

# Peacock
create_zone_file "peacocktv.com" "23.185.0.1" "23.185.0.2"

# Paramount
create_zone_file "paramountplus.com" "23.185.0.1" "23.185.0.2"
create_zone_file "paramount.com" "23.185.0.1" "23.185.0.2"

# ESPN
create_zone_file "espn.com" "23.185.0.1" "23.185.0.2"
create_zone_file "espnplus.com" "23.185.0.1" "23.185.0.2"

# Prime Video
create_zone_file "primevideo.com" "52.85.124.14" "52.85.124.15"
create_zone_file "amazonvideo.com" "52.85.124.14" "52.85.124.15"

# Apple TV
create_zone_file "tv.apple.com" "17.253.144.10" "17.253.144.11"

# Other services
create_zone_file "sling.com" "23.185.0.1" "23.185.0.2"
create_zone_file "discoveryplus.com" "23.185.0.1" "23.185.0.2"
create_zone_file "tubi.tv" "23.185.0.1" "23.185.0.2"
create_zone_file "crackle.com" "23.185.0.1" "23.185.0.2"
create_zone_file "roku.com" "23.185.0.1" "23.185.0.2"
create_zone_file "tntdrama.com" "23.185.0.1" "23.185.0.2"
create_zone_file "tbs.com" "23.185.0.1" "23.185.0.2"
create_zone_file "flosports.tv" "23.185.0.1" "23.185.0.2"
create_zone_file "magellantv.com" "23.185.0.1" "23.185.0.2"
create_zone_file "aetv.com" "23.185.0.1" "23.185.0.2"
create_zone_file "directv.com" "23.185.0.1" "23.185.0.2"
create_zone_file "britbox.com" "23.185.0.1" "23.185.0.2"
create_zone_file "dazn.com" "23.185.0.1" "23.185.0.2"
create_zone_file "fubo.tv" "23.185.0.1" "23.185.0.2"
create_zone_file "philo.com" "23.185.0.1" "23.185.0.2"
create_zone_file "dishanywhere.com" "23.185.0.1" "23.185.0.2"
create_zone_file "xumo.tv" "23.185.0.1" "23.185.0.2"
create_zone_file "hgtv.com" "23.185.0.1" "23.185.0.2"
create_zone_file "amcplus.com" "23.185.0.1" "23.185.0.2"
create_zone_file "mgmplus.com" "23.185.0.1" "23.185.0.2"

echo ""
echo "=== Zone Files Created ==="
echo "Verifying zone files..."
ls -lh "$ZONES_DIR"

echo ""
echo "Testing zone file syntax..."
for zone_file in "$ZONES_DIR"/db.*; do
    if [ -f "$zone_file" ]; then
        domain=$(basename "$zone_file" | sed 's/db\.//' | tr '_' '.')
        if named-checkzone "$domain" "$zone_file" > /dev/null 2>&1; then
            echo "✅ $domain zone file is valid"
        else
            echo "❌ $domain zone file has errors"
            named-checkzone "$domain" "$zone_file"
        fi
    fi
done

echo ""
echo "=== Restarting BIND9 ==="
systemctl restart bind9
sleep 2

echo ""
echo "=== Testing DNS Resolution ==="
echo "Testing netflix.com:"
dig @127.0.0.1 netflix.com +short

echo ""
echo "Testing disneyplus.com:"
dig @127.0.0.1 disneyplus.com +short

echo ""
echo "Testing hulu.com:"
dig @127.0.0.1 hulu.com +short

echo ""
echo "=== Complete ==="

