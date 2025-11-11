#!/bin/bash
# Create a minimal stream.conf to test
# Run: sudo bash fix-nginx-stream-simple.sh

set -e

echo "=========================================="
echo "Creating Minimal Stream Configuration"
echo "=========================================="

# Stop nginx
systemctl stop nginx 2>/dev/null || true
pkill nginx 2>/dev/null || true
sleep 2

# Backup current stream.conf
cp /etc/nginx/stream.conf /etc/nginx/stream.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Create a minimal stream.conf with just one domain to test
echo "Creating minimal stream.conf for testing..."

cat > /etc/nginx/stream.conf <<'EOF'
stream {
    # Minimal test configuration
    map $ssl_preread_server_name $ssl_target {
        default $ssl_preread_server_name:443;
        ~^(.*|)netflix\.com$    $ssl_preread_server_name:443;
    }

    map $ssl_preread_server_name $http_target {
        default $ssl_preread_server_name:80;
        ~^(.*|)netflix\.com$    $ssl_preread_server_name:80;
    }

    # HTTPS listener (port 443)
    server {
        listen 443;
        proxy_pass $ssl_target;
        ssl_preread on;
    }

    # HTTP listener (port 80)
    server {
        listen 80;
        proxy_pass $http_target;
    }
}
EOF

echo "✅ Created minimal stream.conf"

# Test configuration
echo ""
echo "Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Configuration is valid"
    
    # Start nginx
    echo ""
    echo "Starting Nginx with minimal config..."
    systemctl start nginx
    sleep 3
    
    if systemctl is-active --quiet nginx; then
        echo ""
        echo "=========================================="
        echo "✅ NGINX IS RUNNING WITH MINIMAL CONFIG!"
        echo "=========================================="
        systemctl status nginx --no-pager -l | head -15
        echo ""
        echo "Ports:"
        ss -tulnp | grep nginx
        echo ""
        echo "✅ Success! Now we can add more domains gradually"
        echo ""
        echo "To add all domains, run:"
        echo "  curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/fix-stream-conf-final.sh | sudo bash"
    else
        echo "❌ Still failed even with minimal config"
        echo ""
        echo "Error:"
        tail -10 /var/log/nginx/error.log 2>/dev/null || journalctl -xeu nginx.service --no-pager | tail -10
        echo ""
        echo "This suggests the issue is not with the domain list, but with the stream block itself"
        exit 1
    fi
else
    echo "❌ Configuration test failed:"
    nginx -t 2>&1
    exit 1
fi

