#!/bin/bash
# Try to start Nginx manually and capture the exact error
# Run: sudo bash start-nginx-manual.sh

set -e

echo "=========================================="
echo "Manual Nginx Start - Capturing Error"
echo "=========================================="

# Stop any existing nginx
systemctl stop nginx 2>/dev/null || true
pkill nginx 2>/dev/null || true
sleep 1

# Check config
echo "1. Testing configuration..."
nginx -t
echo ""

# Try to start in foreground to see error
echo "2. Attempting to start Nginx in foreground..."
echo "This will show the exact error:"
echo ""

# Start in foreground with timeout
timeout 5 nginx -g "daemon off;" 2>&1 || {
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo "Nginx started successfully (timeout reached)"
        pkill nginx
    else
        echo ""
        echo "Nginx failed to start. Exit code: $EXIT_CODE"
        echo ""
        echo "Checking systemd logs:"
        journalctl -xeu nginx.service --no-pager | tail -15
    fi
}

echo ""
echo "3. Checking if nginx process is running:"
ps aux | grep nginx | grep -v grep || echo "No nginx processes"

echo ""
echo "4. Checking ports:"
ss -tulnp | grep -E ':80 |:443 ' || echo "Ports 80 and 443 are free"

echo ""
echo "5. Checking for any error logs:"
tail -20 /var/log/nginx/error.log 2>/dev/null || echo "No error log found"

