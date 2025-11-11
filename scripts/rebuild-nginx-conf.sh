#!/bin/bash
# Rebuild nginx.conf from scratch, keeping only essentials
# Run: sudo bash rebuild-nginx-conf.sh

set -e

echo "=========================================="
echo "Rebuilding nginx.conf from Scratch"
echo "=========================================="

# Stop Nginx
systemctl stop nginx 2>/dev/null || true

# Backup current nginx.conf
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    echo "✅ Backed up current nginx.conf"
fi

# Create a clean nginx.conf
echo "Creating clean nginx.conf..."

cat > /etc/nginx/nginx.conf <<'EOF'
# Load stream module for SNI-based proxying
load_module /etc/nginx/modules/ngx_stream_module.so;

user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
    # multi_accept on;
}

http {
    ##
    # Basic Settings
    ##
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    # server_tokens off;

    # server_names_hash_bucket_size 64;
    # server_name_in_redirect off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ##
    # SSL Settings
    ##
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
    ssl_prefer_server_ciphers on;

    ##
    # Logging Settings
    ##
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    ##
    # Gzip Settings
    ##
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    ##
    # Virtual Host Configs
    ##
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}

# Stream configuration for SNI-based proxying
# This is included at root level (outside http block)
include /etc/nginx/stream.conf;
EOF

echo "✅ Created clean nginx.conf"

# Verify stream.conf exists
if [ ! -f /etc/nginx/stream.conf ]; then
    echo "❌ stream.conf not found at /etc/nginx/stream.conf"
    echo "Please ensure stream.conf exists before continuing"
    exit 1
fi

# Verify stream.conf structure
echo ""
echo "Verifying stream.conf structure..."
if grep -q "^stream {" /etc/nginx/stream.conf; then
    echo "✅ stream.conf has correct structure"
else
    echo "⚠️ stream.conf may not have stream block"
    head -10 /etc/nginx/stream.conf
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
        echo ""
        echo "nginx.conf has been rebuilt cleanly."
        echo "All stream configuration is in /etc/nginx/stream.conf"
    else
        echo "❌ Nginx failed to start"
        journalctl -xeu nginx.service --no-pager | tail -20
        exit 1
    fi
else
    echo "❌ Nginx configuration test failed:"
    nginx -t 2>&1
    echo ""
    echo "Checking stream.conf:"
    head -20 /etc/nginx/stream.conf
    exit 1
fi

