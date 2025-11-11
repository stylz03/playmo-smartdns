#!/bin/bash
# Generate streaming service IP ranges for WireGuard split-tunneling
# This script resolves domains from services.json and creates IP ranges

set -e

SERVICES_JSON="${1:-services.json}"
OUTPUT_FILE="${2:-streaming-ip-ranges.txt}"

if [ ! -f "$SERVICES_JSON" ]; then
    echo "Error: $SERVICES_JSON not found"
    exit 1
fi

echo "Generating streaming IP ranges from $SERVICES_JSON..."
echo "This may take a few minutes..."

# Extract domains from services.json
DOMAINS=$(jq -r 'to_entries[] | select(.value == true) | .key' "$SERVICES_JSON" 2>/dev/null || \
    python3 -c "import json, sys; data=json.load(open('$SERVICES_JSON')); print('\n'.join([k for k,v in data.items() if v]))")

if [ -z "$DOMAINS" ]; then
    echo "Error: No streaming domains found in $SERVICES_JSON"
    exit 1
fi

# Temporary file for IPs
TEMP_IPS=$(mktemp)
TEMP_RANGES=$(mktemp)

echo "Resolving IPs for streaming domains..."
while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        echo "  Resolving $domain..."
        # Resolve A and AAAA records
        dig +short "$domain" A "$domain" AAAA 2>/dev/null | grep -E '^[0-9]' >> "$TEMP_IPS" || true
        # Also try common subdomains
        for subdomain in "www.$domain" "api.$domain" "cdn.$domain" "stream.$domain"; do
            dig +short "$subdomain" A "$subdomain" AAAA 2>/dev/null | grep -E '^[0-9]' >> "$TEMP_IPS" || true
        done
    fi
done <<< "$DOMAINS"

# Remove duplicates and IPv6 (keep only IPv4)
sort -u "$TEMP_IPS" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' > "${TEMP_IPS}.ipv4"

# Convert IPs to CIDR ranges (simplified - groups by /24)
echo "Converting IPs to CIDR ranges..."
cat "${TEMP_IPS}.ipv4" | while IFS= read -r ip; do
    # Extract network portion (first 3 octets)
    NETWORK=$(echo "$ip" | cut -d. -f1-3)
    echo "${NETWORK}.0/24" >> "$TEMP_RANGES"
done

# Sort and deduplicate ranges
sort -u "$TEMP_RANGES" > "$OUTPUT_FILE"

# Count results
IP_COUNT=$(wc -l < "${TEMP_IPS}.ipv4")
RANGE_COUNT=$(wc -l < "$OUTPUT_FILE")

echo ""
echo "✅ Generated $RANGE_COUNT IP ranges from $IP_COUNT unique IPs"
echo "📄 Output saved to: $OUTPUT_FILE"
echo ""
echo "Sample ranges (first 10):"
head -n 10 "$OUTPUT_FILE"

# Cleanup
rm -f "$TEMP_IPS" "${TEMP_IPS}.ipv4" "$TEMP_RANGES"

echo ""
echo "Next steps:"
echo "1. Review $OUTPUT_FILE"
echo "2. Use these ranges in WireGuard client AllowedIPs"
echo "3. Update ranges periodically (streaming services change IPs)"

