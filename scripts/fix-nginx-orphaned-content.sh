#!/bin/bash
# Fix orphaned content in nginx.conf after stream block removal
# Run: sudo bash fix-nginx-orphaned-content.sh

set -e

echo "=========================================="
echo "Fixing Orphaned Content in nginx.conf"
echo "=========================================="

# Stop Nginx
systemctl stop nginx 2>/dev/null || true

# Backup nginx.conf
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Check what's around line 96
echo "Checking content around line 96:"
sed -n '90,100p' /etc/nginx/nginx.conf
echo ""

# Find where the http block ends
HTTP_END_LINE=$(grep -n "^}" /etc/nginx/nginx.conf | tail -1 | cut -d: -f1 || echo "0")
echo "HTTP block ends at line: $HTTP_END_LINE"

# Find any orphaned stream-related directives
echo ""
echo "Checking for orphaned stream-related directives..."
if grep -n "^[[:space:]]*map\|^[[:space:]]*server\|^[[:space:]]*listen" /etc/nginx/nginx.conf | grep -v "include\|#"; then
    echo "⚠️ Found potential orphaned directives"
    grep -n "^[[:space:]]*map\|^[[:space:]]*server\|^[[:space:]]*listen" /etc/nginx/nginx.conf | grep -v "include\|#"
fi

# Remove everything after the http block closing brace until the include
echo ""
echo "Cleaning up nginx.conf..."
# Get everything up to and including the http block closing brace
head -n "$HTTP_END_LINE" /etc/nginx/nginx.conf > /tmp/nginx.conf.clean

# Remove any orphaned content (map, server, listen directives outside blocks)
# Keep only comments, includes, and the load_module
sed -n "$((HTTP_END_LINE + 1)),$"p /etc/nginx/nginx.conf | \
    grep -v "^[[:space:]]*map\|^[[:space:]]*server\|^[[:space:]]*listen\|^[[:space:]]*resolver\|^[[:space:]]*proxy_" | \
    grep -v "^[[:space:]]*}\|^[[:space:]]*{" >> /tmp/nginx.conf.clean || true

# Or simpler: just keep everything up to http block end, then add only the include
head -n "$HTTP_END_LINE" /etc/nginx/nginx.conf > /tmp/nginx.conf.clean2

# Add the include if not present
if ! grep -q "include.*stream.conf" /tmp/nginx.conf.clean2; then
    echo "" >> /tmp/nginx.conf.clean2
    echo "include /etc/nginx/stream.conf;" >> /tmp/nginx.conf.clean2
fi

# Replace nginx.conf
mv /tmp/nginx.conf.clean2 /etc/nginx/nginx.conf

# Ensure load_module is present
if ! grep -q "load_module.*ngx_stream_module" /etc/nginx/nginx.conf; then
    echo "Adding load_module directive..."
    sed -i '1i load_module /etc/nginx/modules/ngx_stream_module.so;' /etc/nginx/nginx.conf
fi

# Verify structure
echo ""
echo "Verifying nginx.conf structure..."
echo "--- Last 10 lines ---"
tail -10 /etc/nginx/nginx.conf
echo ""
echo "--- Checking for orphaned directives ---"
if grep -E "^[[:space:]]*(map|server|listen|resolver|proxy_)" /etc/nginx/nginx.conf | grep -v "^[[:space:]]*#\|include"; then
    echo "⚠️ Still found orphaned directives:"
    grep -E "^[[:space:]]*(map|server|listen|resolver|proxy_)" /etc/nginx/nginx.conf | grep -v "^[[:space:]]*#\|include"
else
    echo "✅ No orphaned directives found"
fi

# Verify stream.conf exists and is valid
echo ""
echo "Verifying stream.conf..."
if [ -f /etc/nginx/stream.conf ]; then
    echo "✅ stream.conf exists"
    echo "First 5 lines:"
    head -5 /etc/nginx/stream.conf
else
    echo "❌ stream.conf not found!"
    exit 1
fi

# Test Nginx configuration
echo ""
echo "Testing Nginx configuration..."
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
    echo "❌ Nginx configuration test failed:"
    nginx -t 2>&1
    echo ""
    echo "Lines 90-100 of nginx.conf:"
    sed -n '90,100p' /etc/nginx/nginx.conf
    exit 1
fi

