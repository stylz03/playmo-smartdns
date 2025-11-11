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

# Generate sniproxy.conf
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

# Table for streaming domains
table {
    # Forward streaming domains to their original destination
    # This allows SNI-based routing while maintaining US-based traffic
EOF

# Add each streaming domain
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
    table {
        # Forward to original destination (transparent proxy)
        # This allows SNI inspection and forwarding
EOF

# Add domains to listen block
while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        echo "        .${domain}" >> "$SNIPROXY_CONF_TMP"
    fi
done <<< "$DOMAINS"

cat >> "$SNIPROXY_CONF_TMP" <<EOF
    }
    # Forward to original destination (transparent mode)
    fallback {
        # If SNI doesn't match, forward to original destination
    }
}

# Listen on port 80 for HTTP traffic (redirects)
listen 0.0.0.0:80 {
    proto http
    table {
EOF

# Add domains to HTTP listen block
while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        echo "        .${domain}" >> "$SNIPROXY_CONF_TMP"
    fi
done <<< "$DOMAINS"

cat >> "$SNIPROXY_CONF_TMP" <<EOF
    }
}
EOF

# Validate configuration
if command -v sniproxy >/dev/null 2>&1; then
    if sniproxy -c "$SNIPROXY_CONF_TMP" -t >/dev/null 2>&1; then
        echo "✅ sniproxy configuration is valid"
    else
        echo "❌ sniproxy configuration validation failed"
        sniproxy -c "$SNIPROXY_CONF_TMP" -t
        rm -f "$SNIPROXY_CONF_TMP"
        exit 1
    fi
fi

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

