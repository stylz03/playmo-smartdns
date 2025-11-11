#!/bin/bash
# Setup nginx stream proxy as hybrid solution with sniproxy
# nginx handles UDP/QUIC, sniproxy handles TCP/TLS
# Run: sudo bash setup-nginx-stream-hybrid.sh

set -e

echo "=========================================="
echo "Setting up Nginx Stream Proxy (Hybrid)"
echo "=========================================="

# Install nginx
if ! command -v nginx >/dev/null 2>&1; then
    echo "Installing nginx..."
    apt-get update
    apt-get install -y nginx
fi

# Backup nginx config
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Create nginx stream config for UDP/QUIC
cat > /etc/nginx/stream.conf <<'EOF'
# Nginx stream proxy for UDP/QUIC traffic
# This complements sniproxy which handles TCP/TLS

# Stream context for UDP forwarding
stream {
    # UDP proxy for QUIC (port 443 UDP)
    server {
        listen 443 udp;
        proxy_pass $upstream;
        proxy_timeout 1s;
        proxy_responses 1;
        error_log /var/log/nginx/stream_udp.log;
    }
    
    # Map SNI to upstream servers for UDP
    map $ssl_preread_server_name $upstream {
        default 127.0.0.1:443;  # Fallback to sniproxy
        ~^.*\.netflix\.com netflix.com:443;
        ~^.*\.nflxvideo\.net nflxvideo.net:443;
        ~^.*\.disneyplus\.com disneyplus.com:443;
        ~^.*\.bamgrid\.com bamgrid.com:443;
        ~^.*\.hulu\.com hulu.com:443;
        ~^.*\.hbomax\.com hbomax.com:443;
        ~^.*\.max\.com max.com:443;
    }
}
EOF

# Update nginx.conf to include stream config
if ! grep -q "include /etc/nginx/stream.conf" /etc/nginx/nginx.conf; then
    # Add stream include at the end
    echo "" >> /etc/nginx/nginx.conf
    echo "# Stream proxy for UDP/QUIC" >> /etc/nginx/nginx.conf
    echo "include /etc/nginx/stream.conf;" >> /etc/nginx/nginx.conf
fi

# Test nginx config
echo ""
echo "Testing nginx configuration..."
if nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    nginx -t
    exit 1
fi

# Restart nginx
echo ""
echo "Restarting nginx..."
systemctl restart nginx
sleep 2

if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
    systemctl status nginx --no-pager -l | head -10
else
    echo "❌ Nginx failed to start"
    journalctl -xeu nginx.service --no-pager | tail -20
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Hybrid Setup Complete"
echo "=========================================="
echo ""
echo "Now you have:"
echo "- Sniproxy: Handles TCP/TLS (port 443 TCP)"
echo "- Nginx Stream: Handles UDP/QUIC (port 443 UDP)"
echo ""
echo "Note: This is a basic setup. Nginx stream UDP proxying"
echo "may need additional configuration for QUIC/HTTP3."

