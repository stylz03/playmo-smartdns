#!/bin/bash
# Sync services.json to sniproxy.conf
# This script reads services.json and generates sniproxy.conf
# Run this on EC2 or in GitHub Actions

set -e

SERVICES_JSON="${1:-services.json}"
SNIPROXY_CONF="${2:-/etc/sniproxy/sniproxy.conf}"
SNIPROXY_CONF_TMP="${SNIPROXY_CONF}.tmp"

if [ ! -f "$SERVICES_JSON" ]; then
    echo "Error: $SERVICES_JSON not found"
    exit 1
fi

echo "Syncing $SERVICES_JSON to $SNIPROXY_CONF..."

# Extract streaming domains from services.json
DOMAINS=$(jq -r 'to_entries[] | select(.value == true) | .key' "$SERVICES_JSON" 2>/dev/null || \
    python3 -c "import json, sys; data=json.load(open('$SERVICES_JSON')); print('\n'.join([k for k,v in data.items() if v]))")

if [ -z "$DOMAINS" ]; then
    echo "Warning: No streaming domains found in $SERVICES_JSON"
    exit 1
fi

# Get EC2 Elastic IP from environment or instance metadata
if [ -z "$EC2_IP" ]; then
    EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "3.151.46.11")
fi

# Generate sniproxy.conf using named table syntax (correct format)
cat > "$SNIPROXY_CONF_TMP" <<EOF
# sniproxy configuration
# Auto-generated from services.json
# Do not edit manually - changes will be overwritten

user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

# Named table for streaming domains
table streaming_domains {
EOF

# Add each streaming domain to the named table
while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        echo "    .${domain}" >> "$SNIPROXY_CONF_TMP"
    fi
done <<< "$DOMAINS"

cat >> "$SNIPROXY_CONF_TMP" <<EOF
}

# Listen on port 443 for HTTPS traffic
listen 0.0.0.0:443 {
    proto tls
    table streaming_domains
}

# Listen on port 80 for HTTP traffic
listen 0.0.0.0:80 {
    proto http
    table streaming_domains
}
EOF

# Validate configuration (sniproxy doesn't have -t flag, so we'll just check if file exists and is readable)
if [ ! -f "$SNIPROXY_CONF_TMP" ]; then
    echo "❌ Configuration file was not created"
    exit 1
fi

# Check basic syntax (file is readable and has required sections)
if ! grep -q "listen.*443" "$SNIPROXY_CONF_TMP" || ! grep -q "table" "$SNIPROXY_CONF_TMP"; then
    echo "❌ Configuration appears to be missing required sections"
    rm -f "$SNIPROXY_CONF_TMP"
    exit 1
fi

echo "✅ Configuration file created and appears valid"

# Replace config file
if [ -f "$SNIPROXY_CONF" ]; then
    mv "$SNIPROXY_CONF" "${SNIPROXY_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
fi
mv "$SNIPROXY_CONF_TMP" "$SNIPROXY_CONF"
chmod 644 "$SNIPROXY_CONF"

echo "✅ Updated $SNIPROXY_CONF with $(echo "$DOMAINS" | wc -l) streaming domains"

# Restart sniproxy if running
if systemctl is-active --quiet sniproxy 2>/dev/null; then
    echo "Restarting sniproxy..."
    systemctl restart sniproxy
    echo "✅ sniproxy restarted"
fi

