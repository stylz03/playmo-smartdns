#!/bin/bash
# Fix Nginx systemd service - the issue is with ExecStartPre or service type
# Run: sudo bash fix-nginx-systemd-service.sh

set -e

echo "=========================================="
echo "Fixing Nginx Systemd Service"
echo "=========================================="

# Stop nginx
systemctl stop nginx 2>/dev/null || true
pkill nginx 2>/dev/null || true
sleep 2

# The issue: ExecStartPre has invalid flags
# Also, Type=forking might be causing issues
# Let's create a proper systemd service

echo "1. Creating corrected systemd service..."

cat > /etc/systemd/system/nginx.service <<'EOF'
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Created corrected systemd service"

# Reload systemd
echo ""
echo "2. Reloading systemd..."
systemctl daemon-reload

# Ensure no nginx processes are running
echo ""
echo "3. Ensuring no nginx processes are running..."
pkill -9 nginx 2>/dev/null || true
sleep 2

# Check ports one more time
echo ""
echo "4. Final port check..."
if lsof -i :80 2>/dev/null | grep -q LISTEN || ss -tulnp | grep -q ':80 '; then
    echo "⚠️ Port 80 still in use:"
    lsof -i :80 2>/dev/null || ss -tulnp | grep ':80 '
    PID=$(lsof -ti :80 2>/dev/null | head -1 || ss -tulnp | grep ':80 ' | grep -oE 'pid=[0-9]+' | cut -d= -f2 | head -1 || echo "")
    if [ -n "$PID" ]; then
        echo "Killing PID $PID..."
        kill -9 "$PID" 2>/dev/null || true
        sleep 2
    fi
else
    echo "✅ Port 80 is free"
fi

# Remove any stale PID file
rm -f /run/nginx.pid

# Try starting
echo ""
echo "5. Starting Nginx with corrected service..."
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
    echo "✅ Nginx is now running via systemd!"
else
    echo "❌ Still failed"
    echo ""
    echo "Error details:"
    journalctl -xeu nginx.service --no-pager | tail -20
    echo ""
    echo "Trying alternative: Change service type to simple..."
    # Try with Type=simple instead
    sed -i 's/Type=forking/Type=simple/' /etc/systemd/system/nginx.service
    sed -i "s|ExecStart=.*|ExecStart=/usr/sbin/nginx -g 'daemon off;'|" /etc/systemd/system/nginx.service
    systemctl daemon-reload
    systemctl start nginx
    sleep 3
    
    if systemctl is-active --quiet nginx; then
        echo "✅ Nginx started with Type=simple!"
        systemctl status nginx --no-pager -l | head -10
    else
        echo "❌ Both methods failed"
        exit 1
    fi
fi

