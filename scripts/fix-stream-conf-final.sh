#!/bin/bash
# Final fix for stream.conf - remove resolver and regenerate
# Run: sudo bash fix-stream-conf-final.sh

set -e

echo "=========================================="
echo "Final Stream.conf Fix"
echo "=========================================="

# Stop nginx
systemctl stop nginx 2>/dev/null || true
pkill nginx 2>/dev/null || true
sleep 2

# Regenerate stream.conf without resolver
echo "Regenerating stream.conf without resolver directives..."

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

if [ ! -f /tmp/services.json ]; then
    echo "Using existing /tmp/services.json if available"
fi

# Run sync script to regenerate
if [ -f /usr/local/bin/sync-nginx-stream-config.sh ]; then
    /usr/local/bin/sync-nginx-stream-config.sh /tmp/services.json /etc/nginx/stream.conf
elif [ -f /tmp/sync-nginx-stream-config.sh ]; then
    bash /tmp/sync-nginx-stream-config.sh /tmp/services.json /etc/nginx/stream.conf
else
    # Download sync script
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -s -f --max-time 30 -H "Authorization: token $GITHUB_TOKEN" \
            https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/sync-nginx-stream-config.sh \
            -o /tmp/sync-nginx-stream-config.sh
    else
        curl -s -f --max-time 30 \
            https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/sync-nginx-stream-config.sh \
            -o /tmp/sync-nginx-stream-config.sh
    fi
    if [ -f /tmp/sync-nginx-stream-config.sh ]; then
        chmod +x /tmp/sync-nginx-stream-config.sh
        bash /tmp/sync-nginx-stream-config.sh /tmp/services.json /etc/nginx/stream.conf
    else
        echo "❌ Could not download sync script"
        exit 1
    fi
fi

# Verify resolver was removed
if grep -q "resolver" /etc/nginx/stream.conf; then
    echo "⚠️ Resolver still found, removing manually..."
    sed -i '/resolver/d' /etc/nginx/stream.conf
    sed -i '/resolver_timeout/d' /etc/nginx/stream.conf
fi

echo "✅ stream.conf regenerated without resolver"

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
        echo "✅ NGINX IS RUNNING!"
        echo "=========================================="
        systemctl status nginx --no-pager -l | head -15
        echo ""
        echo "Ports:"
        ss -tulnp | grep nginx || ss -tulnp | grep -E ':80 |:443 '
        echo ""
        echo "✅ Success! Stream block is working without resolver"
    else
        echo "❌ Still failed"
        journalctl -xeu nginx.service --no-pager | tail -10
        exit 1
    fi
else
    echo "❌ Configuration test failed:"
    nginx -t 2>&1
    exit 1
fi

