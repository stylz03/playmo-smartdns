#!/bin/bash
# Fix Nginx by using Type=simple (foreground mode)
# Run: sudo bash fix-nginx-simple-service.sh

set -e

echo "=========================================="
echo "Fixing Nginx with Type=simple"
echo "=========================================="

# Stop nginx
systemctl stop nginx 2>/dev/null || true
pkill nginx 2>/dev/null || true
sleep 2

# Create service with Type=simple
echo "Creating systemd service with Type=simple..."

cat > /etc/systemd/system/nginx.service <<'EOF'
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=simple
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx -g 'daemon off;'
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Created systemd service with Type=simple"

# Reload systemd
echo ""
echo "Reloading systemd..."
systemctl daemon-reload

# Remove stale PID file
rm -f /run/nginx.pid

# Ensure ports are free
echo ""
echo "Ensuring ports are free..."
pkill -9 nginx 2>/dev/null || true
sleep 2

# Start nginx
echo ""
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
    echo "✅ Nginx is running with Type=simple!"
else
    echo "❌ Still failed"
    echo ""
    echo "Error:"
    journalctl -xeu nginx.service --no-pager | tail -20
    exit 1
fi

