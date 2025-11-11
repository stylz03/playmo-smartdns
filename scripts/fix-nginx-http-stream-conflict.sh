#!/bin/bash
# Fix conflict between http and stream blocks both listening on port 80
# Run: sudo bash fix-nginx-http-stream-conflict.sh

set -e

echo "=========================================="
echo "Fixing HTTP/Stream Port Conflict"
echo "=========================================="

# Check if http block has listen 80
echo "1. Checking for listen directives in http block..."
HTTP_LISTEN=$(grep -A 50 "^http {" /etc/nginx/nginx.conf | grep "listen.*80" || echo "")

if [ -n "$HTTP_LISTEN" ]; then
    echo "⚠️ Found listen 80 in http block:"
    echo "$HTTP_LISTEN"
    echo ""
    echo "This conflicts with stream block listening on port 80"
    echo "We need to remove or comment out the http block's listen 80"
    echo ""
    
    # Check if it's in a default server block
    if echo "$HTTP_LISTEN" | grep -q "default_server\|server_name"; then
        echo "Found in server block - will comment it out"
        # Comment out the server block that listens on 80
        sed -i '/server {/,/}/ {
            /listen.*80/ s/^/#/
        }' /etc/nginx/nginx.conf
    else
        # Just comment out the listen 80 line
        sed -i '/^http {/,/^}/ {
            /listen.*80/ s/^/#/
        }' /etc/nginx/nginx.conf
    fi
    echo "✅ Commented out listen 80 in http block"
else
    echo "✅ No listen 80 found in http block"
fi

# Also check sites-enabled
echo ""
echo "2. Checking sites-enabled for listen 80..."
if [ -d /etc/nginx/sites-enabled ]; then
    SITES_LISTEN=$(grep -r "listen.*80" /etc/nginx/sites-enabled/ 2>/dev/null || echo "")
    if [ -n "$SITES_LISTEN" ]; then
        echo "⚠️ Found listen 80 in sites-enabled:"
        echo "$SITES_LISTEN"
        echo ""
        echo "Disabling sites-enabled temporarily..."
        # Rename sites-enabled to disable it
        if [ ! -d /etc/nginx/sites-enabled.disabled ]; then
            mv /etc/nginx/sites-enabled /etc/nginx/sites-enabled.disabled
            mkdir -p /etc/nginx/sites-enabled
            echo "✅ Disabled sites-enabled"
        fi
    else
        echo "✅ No listen 80 in sites-enabled"
    fi
fi

# Check conf.d for any server blocks listening on 80
echo ""
echo "3. Checking conf.d for listen 80..."
CONFD_LISTEN=$(grep -r "listen.*80" /etc/nginx/conf.d/*.conf 2>/dev/null | grep -v stream.conf || echo "")
if [ -n "$CONFD_LISTEN" ]; then
    echo "⚠️ Found listen 80 in conf.d:"
    echo "$CONFD_LISTEN"
    echo ""
    echo "Commenting out these lines..."
    find /etc/nginx/conf.d/ -name "*.conf" ! -name "stream.conf" -exec sed -i '/listen.*80/ s/^/#/' {} \;
    echo "✅ Commented out listen 80 in conf.d"
else
    echo "✅ No listen 80 in conf.d (excluding stream.conf)"
fi

# Verify stream.conf is correct
echo ""
echo "4. Verifying stream.conf structure..."
if grep -q "listen 80" /etc/nginx/stream.conf; then
    echo "✅ stream.conf has listen 80 (correct)"
else
    echo "⚠️ stream.conf doesn't have listen 80"
fi

# Test configuration
echo ""
echo "5. Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Configuration is valid"
else
    echo "❌ Configuration test failed:"
    nginx -t 2>&1
    exit 1
fi

# Try starting nginx
echo ""
echo "6. Starting Nginx..."
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
    echo "✅ Port conflict resolved!"
else
    echo "❌ Nginx still failed to start"
    journalctl -xeu nginx.service --no-pager | tail -15
    exit 1
fi

