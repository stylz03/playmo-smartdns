#!/bin/bash
# Final comprehensive diagnosis of Nginx startup issue
# Run: sudo bash diagnose-nginx-final.sh

set -e

echo "=========================================="
echo "Final Nginx Diagnosis"
echo "=========================================="

# Get the exact error from the last attempt
echo "1. Last Nginx startup error:"
journalctl -xeu nginx.service --no-pager | tail -30
echo ""

# Try to start manually and capture stderr
echo "2. Attempting manual start with full error output:"
systemctl stop nginx 2>/dev/null || true
pkill nginx 2>/dev/null || true
sleep 1

# Try starting nginx directly
echo "Starting nginx binary directly..."
/usr/sbin/nginx -g "daemon off;" > /tmp/nginx-start.log 2>&1 &
NGINX_PID=$!
sleep 2

if kill -0 $NGINX_PID 2>/dev/null; then
    echo "✅ Nginx started successfully in foreground"
    kill $NGINX_PID 2>/dev/null || true
    sleep 1
else
    echo "❌ Nginx failed to start"
    cat /tmp/nginx-start.log
    wait $NGINX_PID 2>/dev/null || true
fi
echo ""

# Check if it's a permission issue
echo "3. Checking permissions:"
ls -la /usr/sbin/nginx
ls -la /etc/nginx/nginx.conf
ls -la /etc/nginx/stream.conf
echo ""

# Check if stream module can be loaded
echo "4. Testing stream module load:"
if [ -f /etc/nginx/modules/ngx_stream_module.so ]; then
    echo "✅ Module file exists"
    file /etc/nginx/modules/ngx_stream_module.so
    ldd /etc/nginx/modules/ngx_stream_module.so 2>&1 | head -5 || echo "Module dependencies check failed"
else
    echo "❌ Module file not found"
fi
echo ""

# Check systemd service configuration
echo "5. Systemd service configuration:"
systemctl cat nginx.service | head -30
echo ""

# Check if there's a PID file conflict
echo "6. Checking for PID file issues:"
if [ -f /run/nginx.pid ]; then
    OLD_PID=$(cat /run/nginx.pid)
    echo "Found PID file with PID: $OLD_PID"
    if ps -p $OLD_PID > /dev/null 2>&1; then
        echo "⚠️ Process $OLD_PID is still running"
        ps -p $OLD_PID -o pid,cmd
    else
        echo "✅ PID file exists but process is not running (stale PID file)"
        echo "Removing stale PID file..."
        rm -f /run/nginx.pid
    fi
else
    echo "✅ No PID file found"
fi
echo ""

# Try starting via systemd with verbose logging
echo "7. Attempting systemd start with verbose output:"
systemctl start nginx 2>&1
sleep 2

if systemctl is-active --quiet nginx; then
    echo "✅ Nginx started via systemd!"
    systemctl status nginx --no-pager -l | head -15
else
    echo "❌ Still failed via systemd"
    echo "Full error:"
    journalctl -xeu nginx.service --no-pager | grep -A 5 -B 5 "error\|fail\|emerg" | tail -20
fi

