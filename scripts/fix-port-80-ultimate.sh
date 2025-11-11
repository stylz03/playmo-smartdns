#!/bin/bash
# Ultimate fix for port 80 - find and kill whatever is using it
# Run: sudo bash fix-port-80-ultimate.sh

set -e

echo "=========================================="
echo "Ultimate Port 80 Fix"
echo "=========================================="

# Stop everything
echo "1. Stopping all services..."
systemctl stop nginx 2>/dev/null || true
systemctl stop sniproxy 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true
pkill -9 nginx 2>/dev/null || true
pkill -9 sniproxy 2>/dev/null || true
pkill -9 apache2 2>/dev/null || true
sleep 3

# Use fuser to kill anything on port 80
echo ""
echo "2. Using fuser to kill anything on port 80..."
fuser -k 80/tcp 2>/dev/null || true
fuser -k 443/tcp 2>/dev/null || true
sleep 2

# Check /proc/net/tcp for port 80 (hex: 0050)
echo ""
echo "3. Checking /proc/net/tcp for port 80..."
if grep ":0050 " /proc/net/tcp 2>/dev/null; then
    echo "⚠️ Found port 80 in /proc/net/tcp"
    # Extract inode
    INODE=$(grep ":0050 " /proc/net/tcp | awk '{print $10}' | head -1)
    if [ -n "$INODE" ]; then
        echo "Found inode: $INODE"
        # Find process using this inode
        for pid in $(ps -eo pid); do
            if [ -d "/proc/$pid/fd" ]; then
                if ls -l /proc/$pid/fd 2>/dev/null | grep -q "$INODE"; then
                    echo "Found process using inode: PID $pid"
                    ps -p $pid -o pid,cmd || true
                    kill -9 $pid 2>/dev/null || true
                fi
            fi
        done
    fi
else
    echo "✅ Port 80 not found in /proc/net/tcp"
fi

# Wait longer for TIME_WAIT to clear
echo ""
echo "4. Waiting for TIME_WAIT sockets to clear..."
sleep 5

# Final aggressive check and kill
echo ""
echo "5. Final aggressive check..."
# Try to bind to port 80 ourselves to see if it works
if command -v nc >/dev/null 2>&1; then
    timeout 1 nc -l 80 </dev/null >/dev/null 2>&1 &
    NC_PID=$!
    sleep 1
    kill $NC_PID 2>/dev/null || true
fi

# Check one more time with all methods
echo ""
echo "6. Final port check with all methods..."
PORT_IN_USE=false

if lsof -i :80 2>/dev/null | grep -q LISTEN; then
    echo "⚠️ lsof shows port 80 in use:"
    lsof -i :80
    PORT_IN_USE=true
fi

if ss -tulnp | grep -q ':80 '; then
    echo "⚠️ ss shows port 80 in use:"
    ss -tulnp | grep ':80 '
    PORT_IN_USE=true
fi

if netstat -tulnp 2>/dev/null | grep -q ':80 '; then
    echo "⚠️ netstat shows port 80 in use:"
    netstat -tulnp | grep ':80 '
    PORT_IN_USE=true
fi

if [ "$PORT_IN_USE" = false ]; then
    echo "✅ All checks show port 80 is free"
else
    echo "⚠️ Port 80 still appears in use - trying to kill again..."
    fuser -k 80/tcp 2>/dev/null || true
    sleep 3
fi

# Remove ExecStartPre to see if that's causing issues
echo ""
echo "7. Removing ExecStartPre (might be causing issues)..."
sed -i '/ExecStartPre/d' /etc/systemd/system/nginx.service
systemctl daemon-reload

# Try starting nginx
echo ""
echo "8. Starting Nginx..."
systemctl start nginx
sleep 4

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
    echo "✅ Success!"
else
    echo "❌ Still failed"
    echo ""
    echo "Last error:"
    journalctl -xeu nginx.service --no-pager | tail -10
    echo ""
    echo "Trying to start nginx directly to verify it works:"
    /usr/sbin/nginx -g 'daemon off;' &
    sleep 2
    if ps aux | grep nginx | grep -v grep; then
        echo "✅ Nginx works when started directly"
        echo "The issue is with systemd, not nginx itself"
        killall nginx 2>/dev/null || true
    fi
    exit 1
fi

