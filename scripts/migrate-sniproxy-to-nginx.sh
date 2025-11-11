#!/bin/bash
# Migration script: Replace sniproxy with Nginx stream proxy
# Run this on the EC2 instance: curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/migrate-sniproxy-to-nginx.sh | sudo bash

set -e

echo "=========================================="
echo "Migrating from sniproxy to Nginx"
echo "=========================================="

# Stop sniproxy
echo "Stopping sniproxy..."
systemctl stop sniproxy 2>/dev/null || true
systemctl disable sniproxy 2>/dev/null || true

# Install Nginx with stream_ssl_preread_module
echo "Installing Nginx with stream_ssl_preread_module..."
if [ -f /tmp/install-nginx.sh ]; then
    bash /tmp/install-nginx.sh
else
    # Download installation script
    GITHUB_TOKEN="${GITHUB_TOKEN:-}"
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -s -f --max-time 60 --retry 3 -H "Authorization: token $GITHUB_TOKEN" \
            https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/install-nginx-stream.sh \
            -o /tmp/install-nginx.sh || echo "Warning: Could not download install script"
    else
        curl -s -f --max-time 60 --retry 3 \
            https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/install-nginx-stream.sh \
            -o /tmp/install-nginx.sh || echo "Warning: Could not download install script"
    fi
    if [ -f /tmp/install-nginx.sh ]; then
        chmod +x /tmp/install-nginx.sh
        bash /tmp/install-nginx.sh
    else
        echo "❌ Could not download Nginx installation script"
        exit 1
    fi
fi

# Create Nginx stream config directory
mkdir -p /etc/nginx/conf.d

# Download and run sync script
echo "Generating Nginx stream configuration..."
if [ -f /usr/local/bin/sync-nginx-stream-config.sh ]; then
    sync_script="/usr/local/bin/sync-nginx-stream-config.sh"
else
    # Download sync script
    GITHUB_TOKEN="${GITHUB_TOKEN:-}"
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -s -f --max-time 30 --retry 3 -H "Authorization: token $GITHUB_TOKEN" \
            https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/sync-nginx-stream-config.sh \
            -o /tmp/sync-nginx-stream-config.sh || echo "Warning: Could not download sync script"
    else
        curl -s -f --max-time 30 --retry 3 \
            https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/sync-nginx-stream-config.sh \
            -o /tmp/sync-nginx-stream-config.sh || echo "Warning: Could not download sync script"
    fi
    if [ -f /tmp/sync-nginx-stream-config.sh ]; then
        chmod +x /tmp/sync-nginx-stream-config.sh
        sync_script="/tmp/sync-nginx-stream-config.sh"
    else
        echo "❌ Could not download sync script"
        exit 1
    fi
fi

# Download services.json
if [ ! -f /tmp/services.json ]; then
    GITHUB_TOKEN="${GITHUB_TOKEN:-}"
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -s -f --max-time 30 --retry 3 -H "Authorization: token $GITHUB_TOKEN" \
            https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json \
            -o /tmp/services.json || echo "Warning: Could not download services.json"
    else
        curl -s -f --max-time 30 --retry 3 \
            https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json \
            -o /tmp/services.json || echo "Warning: Could not download services.json"
    fi
fi

if [ -f /tmp/services.json ]; then
    $sync_script /tmp/services.json /etc/nginx/conf.d/stream.conf
else
    echo "❌ Could not download services.json"
    exit 1
fi

# Ensure Nginx main config loads stream module
if [ -f /etc/nginx/nginx.conf ]; then
    # Backup original config
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    # Add stream module load if not present
    if ! grep -q "load_module.*ngx_stream_module" /etc/nginx/nginx.conf; then
        sed -i '1a load_module /etc/nginx/modules/ngx_stream_module.so;' /etc/nginx/nginx.conf
    fi
    
    # Add stream block include if not present
    if ! grep -q "include.*stream" /etc/nginx/nginx.conf; then
        sed -i '$a include /etc/nginx/conf.d/stream.conf;' /etc/nginx/nginx.conf
    fi
fi

# Test Nginx configuration
echo "Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration test failed:"
    nginx -t 2>&1 || true
    exit 1
fi

# Start Nginx
echo "Starting Nginx..."
systemctl daemon-reload
systemctl enable nginx
systemctl restart nginx

sleep 2

if systemctl is-active --quiet nginx; then
    echo ""
    echo "=========================================="
    echo "✅ Migration complete! Nginx is running"
    echo "=========================================="
    systemctl status nginx --no-pager -l | head -15
    echo ""
    echo "Ports:"
    ss -tulnp | grep nginx || ss -tulnp | grep -E ':80 |:443 '
    echo ""
    echo "✅ sniproxy has been replaced with Nginx stream proxy"
    echo "You can now remove sniproxy if desired:"
    echo "  systemctl stop sniproxy"
    echo "  systemctl disable sniproxy"
else
    echo ""
    echo "=========================================="
    echo "❌ Nginx failed to start"
    echo "=========================================="
    journalctl -xeu nginx.service --no-pager | tail -20
    exit 1
fi

