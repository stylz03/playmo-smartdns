#!/bin/bash
# Sync services.json to Nginx stream configuration
# This script reads services.json and generates Nginx stream config for SNI-based proxying
# Run this on EC2 or in GitHub Actions

set -e

SERVICES_JSON="${1:-services.json}"
NGINX_STREAM_CONF="${2:-/etc/nginx/conf.d/stream.conf}"
NGINX_STREAM_CONF_TMP="${NGINX_STREAM_CONF}.tmp"

if [ ! -f "$SERVICES_JSON" ]; then
    echo "Error: $SERVICES_JSON not found"
    exit 1
fi

echo "Syncing $SERVICES_JSON to $NGINX_STREAM_CONF..."

# Extract streaming domains from services.json
DOMAINS=$(jq -r 'to_entries[] | select(.value == true) | .key' "$SERVICES_JSON" 2>/dev/null || \
    python3 -c "import json, sys; data=json.load(open('$SERVICES_JSON')); print('\n'.join([k for k,v in data.items() if v]))")

if [ -z "$DOMAINS" ]; then
    echo "Warning: No streaming domains found in $SERVICES_JSON"
    exit 1
fi

# Generate Nginx stream configuration
cat > "$NGINX_STREAM_CONF_TMP" <<'EOF'
# Nginx stream configuration for SNI-based proxying
# Auto-generated from services.json
# Do not edit manually - changes will be overwritten

stream {
    # Resolver for DNS lookups (required for proxy_pass with variables)
    resolver 8.8.8.8 8.8.4.4 1.1.1.1 valid=300s;
    resolver_timeout 5s;

    # Map SNI server name to target
    map $ssl_preread_server_name $ssl_target {
        default $ssl_preread_server_name:443;
EOF

# Add each streaming domain to the map
while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        # Escape dots for regex
        domain_escaped=$(echo "$domain" | sed 's/\./\\./g')
        # Add regex pattern to match domain and all subdomains
        echo "        ~^\(.*|\)${domain_escaped}\$    \${ssl_preread_server_name}:443;" >> "$NGINX_STREAM_CONF_TMP"
    fi
done <<< "$DOMAINS"

cat >> "$NGINX_STREAM_CONF_TMP" <<'EOF'
    }

    # HTTP (port 80) map for non-HTTPS traffic
    map $ssl_preread_server_name $http_target {
        default $ssl_preread_server_name:80;
EOF

# Add HTTP mapping (same domains)
while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        domain_escaped=$(echo "$domain" | sed 's/\./\\./g')
        echo "        ~^\(.*|\)${domain_escaped}\$    \${ssl_preread_server_name}:80;" >> "$NGINX_STREAM_CONF_TMP"
    fi
done <<< "$DOMAINS"

cat >> "$NGINX_STREAM_CONF_TMP" <<'EOF'
    }

    # HTTPS listener (port 443)
    server {
        listen 443;
        proxy_pass $ssl_target;
        proxy_protocol off;
        ssl_preread on;
        proxy_timeout 1s;
        proxy_responses 0;
    }

    # HTTP listener (port 80)
    server {
        listen 80;
        proxy_pass $http_target;
        proxy_protocol off;
        proxy_timeout 1s;
        proxy_responses 0;
    }
}
EOF

# Validate configuration
if [ ! -f "$NGINX_STREAM_CONF_TMP" ]; then
    echo "❌ Configuration file was not created"
    exit 1
fi

# Check basic syntax
if ! grep -q "listen 443" "$NGINX_STREAM_CONF_TMP" || ! grep -q "map.*ssl_preread_server_name" "$NGINX_STREAM_CONF_TMP"; then
    echo "❌ Configuration appears to be missing required sections"
    rm -f "$NGINX_STREAM_CONF_TMP"
    exit 1
fi

echo "✅ Configuration file created and appears valid"

# Replace config file
mkdir -p "$(dirname "$NGINX_STREAM_CONF")"
if [ -f "$NGINX_STREAM_CONF" ]; then
    mv "$NGINX_STREAM_CONF" "${NGINX_STREAM_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
fi
mv "$NGINX_STREAM_CONF_TMP" "$NGINX_STREAM_CONF"
chmod 644 "$NGINX_STREAM_CONF"

echo "✅ Updated $NGINX_STREAM_CONF with $(echo "$DOMAINS" | wc -l) streaming domains"

# Test Nginx configuration
if command -v nginx >/dev/null 2>&1; then
    if nginx -t 2>&1 | grep -q "successful"; then
        echo "✅ Nginx configuration test passed"
    else
        echo "⚠️ Nginx configuration test failed:"
        nginx -t 2>&1 || true
    fi
fi

# Restart Nginx if running
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "Restarting Nginx..."
    systemctl restart nginx
    echo "✅ Nginx restarted"
fi

