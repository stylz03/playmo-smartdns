#!/bin/bash
# Fix Nginx module conflicts
# Run: sudo bash fix-nginx-modules.sh

set -e

echo "=========================================="
echo "Fixing Nginx Module Conflicts"
echo "=========================================="

# Stop Nginx
systemctl stop nginx 2>/dev/null || true

# Remove conflicting module configs
if [ -d /etc/nginx/modules-enabled ]; then
    echo "Removing conflicting module configs..."
    rm -f /etc/nginx/modules-enabled/*.conf 2>/dev/null || true
    echo "✅ Removed conflicting module configs"
fi

# Check if nginx.conf has problematic includes
if [ -f /etc/nginx/nginx.conf ]; then
    # Remove includes for modules-enabled if present
    if grep -q "include.*modules-enabled" /etc/nginx/nginx.conf; then
        echo "Removing modules-enabled include from nginx.conf..."
        sed -i '/include.*modules-enabled/d' /etc/nginx/nginx.conf
        echo "✅ Removed modules-enabled include"
    fi
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

