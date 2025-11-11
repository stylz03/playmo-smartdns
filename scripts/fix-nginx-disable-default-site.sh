#!/bin/bash
# Disable default nginx site and add port 80 back to stream block
# Run: sudo bash fix-nginx-disable-default-site.sh

set -e

echo "=========================================="
echo "Disabling Default Site and Adding Port 80 to Stream"
echo "=========================================="

# Stop nginx
systemctl stop nginx 2>/dev/null || true
sleep 2

# Disable default site
echo "1. Disabling default nginx site..."
if [ -L /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
    echo "✅ Disabled default site"
elif [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
    echo "✅ Removed default site"
else
    echo "✅ Default site already disabled"
fi

# Check if there are any other sites enabled
echo ""
echo "2. Checking for other enabled sites:"
ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo "No sites enabled"
echo ""

# Now regenerate stream.conf with both ports 80 and 443
echo "3. Regenerating stream.conf with both ports 80 and 443..."

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

# Run sync script to regenerate with all domains
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

# Ensure no resolver directives
if grep -q "resolver" /etc/nginx/stream.conf; then
    echo "Removing resolver directives..."
    sed -i '/resolver/d' /etc/nginx/stream.conf
    sed -i '/resolver_timeout/d' /etc/nginx/stream.conf
fi

echo "✅ stream.conf regenerated with all domains and both ports"

# Test configuration
echo ""
echo "4. Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Configuration is valid"
    
    # Start nginx
    echo ""
    echo "5. Starting Nginx with stream block on both ports..."
    systemctl start nginx
    sleep 3
    
    if systemctl is-active --quiet nginx; then
        echo ""
        echo "=========================================="
        echo "✅ NGINX IS RUNNING WITH FULL STREAM CONFIG!"
        echo "=========================================="
        systemctl status nginx --no-pager -l | head -15
        echo ""
        echo "Ports:"
        ss -tulnp | grep nginx
        echo ""
        echo "✅ Success! Nginx is running with:"
        echo "  - Stream block handling ports 80 and 443"
        echo "  - All streaming domains configured"
        echo "  - Default site disabled to avoid conflicts"
        echo ""
        echo "Your SmartDNS with Nginx stream proxy is now active!"
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

