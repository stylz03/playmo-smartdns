#!/bin/bash
# Fix Nginx wildcard include that's catching stream.conf
# Run: sudo bash fix-nginx-wildcard-include.sh

set -e

echo "=========================================="
echo "Fixing Nginx Wildcard Include"
echo "=========================================="

# Stop Nginx
systemctl stop nginx 2>/dev/null || true

# Check for wildcard includes
echo "Checking for wildcard includes in nginx.conf..."
if grep -q "include.*conf.d.*\*" /etc/nginx/nginx.conf; then
    echo "⚠️ Found wildcard include for conf.d - this is including stream.conf"
    echo "Wildcard includes found:"
    grep "include.*conf.d" /etc/nginx/nginx.conf
    
    # Option 1: Move stream.conf out of conf.d
    echo ""
    echo "Moving stream.conf to /etc/nginx/stream.conf (outside conf.d)..."
    if [ -f /etc/nginx/conf.d/stream.conf ]; then
        mv /etc/nginx/conf.d/stream.conf /etc/nginx/stream.conf
        echo "✅ Moved stream.conf to /etc/nginx/stream.conf"
    fi
    
    # Update nginx.conf to include the new location explicitly (at root level)
    if ! grep -q "include.*\/etc\/nginx\/stream.conf" /etc/nginx/nginx.conf; then
        echo "Adding explicit include for /etc/nginx/stream.conf at root level..."
        # Remove any existing stream includes
        sed -i '/include.*stream.conf/d' /etc/nginx/nginx.conf
        # Add at the end (root level, after http block)
        echo "" >> /etc/nginx/nginx.conf
        echo "include /etc/nginx/stream.conf;" >> /etc/nginx/nginx.conf
        echo "✅ Added explicit include at root level"
    fi
else
    echo "✅ No wildcard includes found"
fi

# Also check if stream block is already in nginx.conf
if grep -q "^stream {" /etc/nginx/nginx.conf; then
    echo ""
    echo "Stream block found directly in nginx.conf - this is correct"
fi

# Ensure load_module is present
if ! grep -q "load_module.*ngx_stream_module" /etc/nginx/nginx.conf; then
    echo "Adding load_module directive..."
    sed -i '1i load_module /etc/nginx/modules/ngx_stream_module.so;' /etc/nginx/nginx.conf
fi

# Verify structure
echo ""
echo "Verifying nginx.conf structure..."
echo "--- Includes for conf.d ---"
grep "include.*conf.d" /etc/nginx/nginx.conf || echo "None found"
echo ""
echo "--- Includes for stream.conf ---"
grep "include.*stream.conf" /etc/nginx/nginx.conf || echo "None found"
echo ""
echo "--- Stream block in nginx.conf ---"
grep -A 2 "^stream {" /etc/nginx/nginx.conf | head -3 || echo "Not found directly in nginx.conf"

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
    echo "Checking nginx.conf for issues..."
    echo "--- Last 20 lines ---"
    tail -20 /etc/nginx/nginx.conf
    exit 1
fi

