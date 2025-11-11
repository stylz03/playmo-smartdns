#!/bin/bash
# Create zone files for streaming domains - resolve to EC2 Elastic IP for sniproxy
# Run this on EC2: sudo bash create-zone-files-sniproxy.sh

set -e

EC2_IP="${1:-3.151.46.11}"
ZONES_DIR="/etc/bind/zones"

echo "=== Creating Zone Files for Streaming Domains ==="
echo "Resolving all streaming domains to EC2 IP: $EC2_IP"
echo ""

mkdir -p "$ZONES_DIR"

# Function to create zone file
create_zone_file() {
    local domain=$1
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
@       IN      A       $EC2_IP
EOF
    chown root:bind "$zone_file"
    chmod 644 "$zone_file"
    echo "✅ Created: $zone_file"
}

# Get domains from services.json (download if not present)
if [ ! -f /tmp/services.json ]; then
    echo "Downloading services.json..."
    curl -s -f https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json -o /tmp/services.json || {
        echo "Error: Could not download services.json"
        exit 1
    }
fi

# Extract domains from services.json
DOMAINS=$(jq -r 'to_entries[] | select(.value == true) | .key' /tmp/services.json 2>/dev/null || \
    python3 -c "import json, sys; data=json.load(open('/tmp/services.json')); print('\n'.join([k for k,v in data.items() if v]))")

if [ -z "$DOMAINS" ]; then
    echo "Error: No streaming domains found in services.json"
    exit 1
fi

# Create zone files for all streaming domains
echo "Creating zone files for streaming domains..."
while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        create_zone_file "$domain"
    fi
done <<< "$DOMAINS"

echo ""
echo "=== Zone Files Created ==="
echo "Total zones: $(ls -1 $ZONES_DIR/db.* 2>/dev/null | wc -l)"
echo ""
echo "All streaming domains will resolve to: $EC2_IP"
echo "Traffic will flow through sniproxy for HTTPS forwarding"

