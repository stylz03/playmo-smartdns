#!/bin/bash
# Fix Nginx stream config include placement
# The stream block must be at root level, not inside http block
# Run: sudo bash fix-nginx-stream-include.sh

set -e

echo "=========================================="
echo "Fixing Nginx Stream Config Include"
echo "=========================================="

# Stop Nginx
systemctl stop nginx 2>/dev/null || true

# Backup nginx.conf
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Check current nginx.conf structure
echo "Checking nginx.conf structure..."
if grep -q "include.*stream.conf" /etc/nginx/nginx.conf; then
    echo "Found stream.conf include, checking placement..."
    
    # Check if it's inside http block
    HTTP_START=$(grep -n "^http {" /etc/nginx/nginx.conf | cut -d: -f1 || echo "")
    HTTP_END=$(grep -n "^}" /etc/nginx/nginx.conf | tail -1 | cut -d: -f1 || echo "")
    INCLUDE_LINE=$(grep -n "include.*stream.conf" /etc/nginx/nginx.conf | cut -d: -f1 || echo "")
    
    if [ -n "$HTTP_START" ] && [ -n "$HTTP_END" ] && [ -n "$INCLUDE_LINE" ]; then
        if [ "$INCLUDE_LINE" -gt "$HTTP_START" ] && [ "$INCLUDE_LINE" -lt "$HTTP_END" ]; then
            echo "❌ stream.conf include is inside http block - fixing..."
            # Remove the include from inside http block
            sed -i '/include.*stream.conf/d' /etc/nginx/nginx.conf
        fi
    fi
fi

# Ensure stream.conf include is at the end (root level)
if ! grep -q "include.*stream.conf" /etc/nginx/nginx.conf; then
    echo "Adding stream.conf include at root level..."
    # Add at the very end of the file
    echo "" >> /etc/nginx/nginx.conf
    echo "include /etc/nginx/conf.d/stream.conf;" >> /etc/nginx/nginx.conf
    echo "✅ Added stream.conf include at root level"
else
    echo "✅ stream.conf include already present"
fi

# Verify the include is outside http block
echo ""
echo "Verifying include placement..."
HTTP_END_LINE=$(grep -n "^}" /etc/nginx/nginx.conf | tail -1 | cut -d: -f1 || echo "0")
INCLUDE_LINE=$(grep -n "include.*stream.conf" /etc/nginx/nginx.conf | cut -d: -f1 || echo "0")

if [ "$INCLUDE_LINE" -gt "$HTTP_END_LINE" ]; then
    echo "✅ stream.conf include is correctly placed after http block"
else
    echo "⚠️ stream.conf include may be in wrong location"
    echo "HTTP block ends at line: $HTTP_END_LINE"
    echo "Include is at line: $INCLUDE_LINE"
fi

# Test Nginx configuration
echo ""
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
    else
        echo "❌ Nginx failed to start"
        journalctl -xeu nginx.service --no-pager | tail -20
        exit 1
    fi
else
    echo "❌ Nginx configuration test failed:"
    nginx -t 2>&1
    echo ""
    echo "Current nginx.conf (last 10 lines):"
    tail -10 /etc/nginx/nginx.conf
    echo ""
    echo "Checking stream.conf structure:"
    head -10 /etc/nginx/conf.d/stream.conf
    exit 1
fi

