#!/bin/bash
# Final fix for Nginx stream configuration
# The stream block must be defined directly in nginx.conf or included correctly
# Run: sudo bash fix-nginx-stream-final.sh

set -e

echo "=========================================="
echo "Final Fix for Nginx Stream Configuration"
echo "=========================================="

# Stop Nginx
systemctl stop nginx 2>/dev/null || true

# Backup files
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Check current nginx.conf structure
echo "Current nginx.conf structure:"
echo "--- First 10 lines ---"
head -10 /etc/nginx/nginx.conf
echo ""
echo "--- Last 15 lines ---"
tail -15 /etc/nginx/nginx.conf
echo ""

# Check stream.conf structure
echo "Current stream.conf structure:"
head -10 /etc/nginx/conf.d/stream.conf
echo ""

# The issue: When including a file with stream{}, it must be at root level
# But the include directive placement might be wrong, OR we need to include the content directly

# Option 1: Include the stream.conf content directly in nginx.conf
echo "Fixing by including stream block content directly in nginx.conf..."

# Remove any existing stream.conf include
sed -i '/include.*stream.conf/d' /etc/nginx/nginx.conf

# Get the stream block content from stream.conf (without the stream { wrapper if it exists)
STREAM_CONTENT=$(cat /etc/nginx/conf.d/stream.conf)

# Check if stream.conf already has stream { wrapper
if echo "$STREAM_CONTENT" | grep -q "^stream {"; then
    echo "stream.conf has stream { wrapper - including it directly"
    # Add the entire stream block at the end of nginx.conf
    echo "" >> /etc/nginx/nginx.conf
    cat /etc/nginx/conf.d/stream.conf >> /etc/nginx/nginx.conf
else
    echo "stream.conf doesn't have stream { wrapper - wrapping it"
    # Wrap it in stream block
    echo "" >> /etc/nginx/nginx.conf
    echo "stream {" >> /etc/nginx/nginx.conf
    cat /etc/nginx/conf.d/stream.conf >> /etc/nginx/nginx.conf
    echo "}" >> /etc/nginx/nginx.conf
fi

# Ensure load_module is at the top
if ! grep -q "load_module.*ngx_stream_module" /etc/nginx/nginx.conf; then
    echo "Adding load_module directive..."
    sed -i '1i load_module /etc/nginx/modules/ngx_stream_module.so;' /etc/nginx/nginx.conf
fi

echo ""
echo "Updated nginx.conf structure:"
echo "--- First 5 lines ---"
head -5 /etc/nginx/nginx.conf
echo ""
echo "--- Last 10 lines ---"
tail -10 /etc/nginx/nginx.conf
echo ""

# Test Nginx configuration
echo "Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Nginx configuration is valid"
    
    # Start Nginx
    echo "Starting Nginx..."
    systemctl start nginx
    sleep 2
    
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
    echo "❌ Nginx configuration test failed:"
    nginx -t 2>&1
    exit 1
fi

