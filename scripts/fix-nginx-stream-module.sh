#!/bin/bash
# Fix Nginx stream module loading
# Run: sudo bash fix-nginx-stream-module.sh

set -e

echo "=========================================="
echo "Fixing Nginx Stream Module"
echo "=========================================="

# Stop Nginx
systemctl stop nginx 2>/dev/null || true

# Check if stream module exists
if [ -f /etc/nginx/modules/ngx_stream_module.so ]; then
    echo "✅ Stream module found: /etc/nginx/modules/ngx_stream_module.so"
else
    echo "❌ Stream module not found at /etc/nginx/modules/ngx_stream_module.so"
    echo "Checking alternative locations..."
    find /usr -name "ngx_stream_module.so" 2>/dev/null | head -5 || echo "Module not found"
    echo ""
    echo "The stream module may not have been compiled correctly."
    echo "Please re-run the Nginx installation script."
    exit 1
fi

# Backup nginx.conf
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Check if load_module is already in nginx.conf
if ! grep -q "load_module.*ngx_stream_module" /etc/nginx/nginx.conf; then
    echo "Adding stream module load directive to nginx.conf..."
    # Add at the very top of the file (before any other directives)
    sed -i '1i load_module /etc/nginx/modules/ngx_stream_module.so;' /etc/nginx/nginx.conf
    echo "✅ Added load_module directive"
else
    echo "✅ load_module directive already present"
fi

# Check if stream.conf include is present
if ! grep -q "include.*stream.conf" /etc/nginx/nginx.conf; then
    echo "Adding stream.conf include to nginx.conf..."
    # Add at the end of the file (outside http block)
    echo "" >> /etc/nginx/nginx.conf
    echo "include /etc/nginx/conf.d/stream.conf;" >> /etc/nginx/nginx.conf
    echo "✅ Added stream.conf include"
else
    echo "✅ stream.conf include already present"
fi

# Verify nginx.conf structure
echo ""
echo "Checking nginx.conf structure..."
if grep -q "load_module.*ngx_stream_module" /etc/nginx/nginx.conf && grep -q "include.*stream.conf" /etc/nginx/nginx.conf; then
    echo "✅ nginx.conf structure looks correct"
else
    echo "⚠️ nginx.conf may need manual editing"
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
    echo "Current nginx.conf (first 20 lines):"
    head -20 /etc/nginx/nginx.conf
    exit 1
fi

