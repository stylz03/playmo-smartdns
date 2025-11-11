#!/bin/bash
# Fix Nginx stream forwarding - add resolver and fix proxy_pass
# Run: sudo bash fix-nginx-stream-forwarding.sh

set -e

echo "=========================================="
echo "Fixing Nginx Stream Forwarding"
echo "=========================================="

# Stop nginx
systemctl stop nginx 2>/dev/null || true
sleep 2

# Backup stream.conf
cp /etc/nginx/stream.conf /etc/nginx/stream.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# The issue: proxy_pass with variables needs a resolver
# Also, we need to ensure the target is resolved correctly
echo "Fixing stream.conf to add resolver and improve forwarding..."

# Regenerate stream.conf with resolver at stream level (not server level)
# Download services.json
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
if [ -n "$GITHUB_TOKEN" ]; then
    curl -s -f --max-time 30 -H "Authorization: token $GITHUB_TOKEN" \
        https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json \
        -o /tmp/services.json || echo "Could not download services.json"
else
    curl -s -f --max-time 30 \
        https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json \
        -o /tmp/services.json || echo "Could not download services.json"
fi

# Extract domains
DOMAINS=$(jq -r 'to_entries[] | select(.value == true) | .key' /tmp/services.json 2>/dev/null || \
    python3 -c "import json, sys; data=json.load(open('/tmp/services.json')); print('\n'.join([k for k,v in data.items() if v]))")

# Create new stream.conf with resolver at stream level
cat > /etc/nginx/stream.conf <<'EOF'
stream {
    # Resolver for DNS lookups (required for proxy_pass with variables)
    resolver 8.8.8.8 8.8.4.4 1.1.1.1 valid=300s;
    resolver_timeout 5s;

    # Map SNI server name to target
    map $ssl_preread_server_name $ssl_target {
        default $ssl_preread_server_name:443;
EOF

# Add streaming domains
while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        domain_escaped=$(echo "$domain" | sed 's/\./\\./g')
        echo "        ~^(.*|)${domain_escaped}\$    \${ssl_preread_server_name}:443;" >> /etc/nginx/stream.conf
    fi
done <<< "$DOMAINS"

cat >> /etc/nginx/stream.conf <<'EOF'
    }

    # HTTP map
    map $ssl_preread_server_name $http_target {
        default $ssl_preread_server_name:80;
EOF

# Add HTTP mapping
while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        domain_escaped=$(echo "$domain" | sed 's/\./\\./g')
        echo "        ~^(.*|)${domain_escaped}\$    \${ssl_preread_server_name}:80;" >> /etc/nginx/stream.conf
    fi
done <<< "$DOMAINS"

cat >> /etc/nginx/stream.conf <<'EOF'
    }

    # HTTPS listener (port 443)
    server {
        listen 443;
        proxy_pass $ssl_target;
        proxy_protocol off;
        ssl_preread on;
        proxy_timeout 1s;
        proxy_responses 0;
        # proxy_bind $remote_addr transparent;  # Requires root or special permissions
    }

    # HTTP listener (port 80)
    server {
        listen 80;
        proxy_pass $http_target;
        proxy_protocol off;
        proxy_timeout 1s;
        proxy_responses 0;
        # proxy_bind $remote_addr transparent;  # Requires root or special permissions
    }
}
EOF

echo "✅ Updated stream.conf with resolver at stream level"

# Test configuration
echo ""
echo "Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Configuration is valid"
    
    # Start nginx
    echo ""
    echo "Starting Nginx..."
    systemctl start nginx
    sleep 3
    
    if systemctl is-active --quiet nginx; then
        echo ""
        echo "=========================================="
        echo "✅ NGINX RESTARTED WITH FIXED CONFIG!"
        echo "=========================================="
        systemctl status nginx --no-pager -l | head -10
        echo ""
        echo "Testing HTTPS forwarding..."
        sleep 2
        curl -v --resolve netflix.com:443:3.151.46.11 https://netflix.com --max-time 10 2>&1 | grep -E "HTTP|SSL|TLS|Connected" | head -5 || echo "Test completed"
    else
        echo "❌ Nginx failed to start"
        journalctl -xeu nginx.service --no-pager | tail -10
        exit 1
    fi
else
    echo "❌ Configuration test failed:"
    nginx -t 2>&1
    exit 1
fi

