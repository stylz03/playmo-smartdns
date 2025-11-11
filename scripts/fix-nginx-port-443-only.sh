#!/bin/bash
# Test Nginx with only port 443 in stream block (no port 80)
# Run: sudo bash fix-nginx-port-443-only.sh

set -e

echo "=========================================="
echo "Testing Nginx with Port 443 Only"
echo "=========================================="

# Stop nginx
systemctl stop nginx 2>/dev/null || true
pkill nginx 2>/dev/null || true
sleep 2

# Check for any listen 80 directives in all nginx configs
echo "1. Checking for ALL listen 80 directives:"
grep -r "listen.*80" /etc/nginx/ 2>/dev/null | grep -v "#" || echo "No listen 80 found"
echo ""

# Create stream.conf with only port 443
echo "2. Creating stream.conf with only port 443 (no port 80)..."
cat > /etc/nginx/stream.conf <<'EOF'
stream {
    # Test with HTTPS only (port 443)
    map $ssl_preread_server_name $ssl_target {
        default $ssl_preread_server_name:443;
        ~^(.*|)netflix\.com$    $ssl_preread_server_name:443;
        ~^(.*|)disneyplus\.com$    $ssl_preread_server_name:443;
    }

    # HTTPS listener (port 443) only
    server {
        listen 443;
        proxy_pass $ssl_target;
        ssl_preread on;
    }
}
EOF

echo "✅ Created stream.conf with only port 443"

# Test configuration
echo ""
echo "3. Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Configuration is valid"
    
    # Start nginx
    echo ""
    echo "4. Starting Nginx with port 443 only..."
    systemctl start nginx
    sleep 3
    
    if systemctl is-active --quiet nginx; then
        echo ""
        echo "=========================================="
        echo "✅ NGINX IS RUNNING WITH PORT 443 ONLY!"
        echo "=========================================="
        systemctl status nginx --no-pager -l | head -15
        echo ""
        echo "Ports:"
        ss -tulnp | grep nginx
        echo ""
        echo "✅ Success! Port 443 works. The issue is specifically with port 80."
        echo ""
        echo "This means something else is using port 80, or there's a conflict."
        echo "For SmartDNS, we primarily need port 443 (HTTPS) anyway."
        echo "Port 80 (HTTP) is less critical for streaming services."
        echo ""
        echo "You can continue with port 443 only, or we can investigate port 80 further."
    else
        echo "❌ Still failed even with port 443 only"
        echo ""
        echo "Error:"
        tail -10 /var/log/nginx/error.log 2>/dev/null || journalctl -xeu nginx.service --no-pager | tail -10
        exit 1
    fi
else
    echo "❌ Configuration test failed:"
    nginx -t 2>&1
    exit 1
fi

