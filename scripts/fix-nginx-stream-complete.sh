#!/bin/bash
# Complete fix for Nginx stream configuration
# Remove include and add stream block directly
# Run: sudo bash fix-nginx-stream-complete.sh

set -e

echo "=========================================="
echo "Complete Fix for Nginx Stream Configuration"
echo "=========================================="

# Stop Nginx
systemctl stop nginx 2>/dev/null || true

# Backup files
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Remove ALL includes of stream.conf
echo "Removing stream.conf include directives..."
sed -i '/include.*stream.conf/d' /etc/nginx/nginx.conf
sed -i '/include.*\/etc\/nginx\/conf.d\/stream.conf/d' /etc/nginx/nginx.conf

# Verify it's removed
if grep -q "include.*stream.conf" /etc/nginx/nginx.conf; then
    echo "⚠️ Warning: include still found, trying manual removal..."
    # More aggressive removal
    grep -v "include.*stream.conf" /etc/nginx/nginx.conf > /tmp/nginx.conf.tmp
    mv /tmp/nginx.conf.tmp /etc/nginx/nginx.conf
fi

# Check if stream block already exists in nginx.conf
if grep -q "^stream {" /etc/nginx/nginx.conf; then
    echo "Stream block already exists in nginx.conf, removing it first..."
    # Remove existing stream block (from first "stream {" to matching "}")
    sed -i '/^stream {/,/^}$/d' /etc/nginx/nginx.conf
fi

# Ensure load_module is at the top
if ! grep -q "load_module.*ngx_stream_module" /etc/nginx/nginx.conf; then
    echo "Adding load_module directive..."
    sed -i '1i load_module /etc/nginx/modules/ngx_stream_module.so;' /etc/nginx/nginx.conf
fi

# Append stream block from stream.conf to nginx.conf
echo "Appending stream block to nginx.conf..."
if [ -f /etc/nginx/conf.d/stream.conf ]; then
    # Get the stream block content
    STREAM_CONTENT=$(cat /etc/nginx/conf.d/stream.conf)
    
    # Remove any leading/trailing whitespace
    STREAM_CONTENT=$(echo "$STREAM_CONTENT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Append to nginx.conf
    echo "" >> /etc/nginx/nginx.conf
    echo "$STREAM_CONTENT" >> /etc/nginx/nginx.conf
    
    echo "✅ Stream block appended"
else
    echo "❌ stream.conf not found at /etc/nginx/conf.d/stream.conf"
    exit 1
fi

# Verify structure
echo ""
echo "Verifying nginx.conf structure..."
echo "--- Checking for load_module ---"
grep "load_module.*ngx_stream_module" /etc/nginx/nginx.conf || echo "⚠️ load_module not found"
echo ""
echo "--- Checking for stream block ---"
grep "^stream {" /etc/nginx/nginx.conf || echo "⚠️ stream block not found"
echo ""
echo "--- Checking for include (should be none) ---"
grep "include.*stream" /etc/nginx/nginx.conf || echo "✅ No stream includes found (good)"
echo ""

# Test Nginx configuration
echo "Testing Nginx configuration..."
if nginx -t 2>&1; then
    if nginx -t 2>&1 | grep -q "successful"; then
        echo "✅ Nginx configuration is valid"
        
        # Start Nginx
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
            echo "✅ Stream proxy is now active!"
        else
            echo "❌ Nginx failed to start"
            journalctl -xeu nginx.service --no-pager | tail -20
            exit 1
        fi
    else
        echo "❌ Nginx configuration test failed (but no error shown)"
        nginx -t 2>&1
        exit 1
    fi
else
    echo "❌ Nginx configuration test failed:"
    nginx -t 2>&1
    echo ""
    echo "Last 20 lines of nginx.conf:"
    tail -20 /etc/nginx/nginx.conf
    exit 1
fi

