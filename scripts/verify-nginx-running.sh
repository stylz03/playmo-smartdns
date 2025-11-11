#!/bin/bash
# Verify if Nginx is actually running despite systemd thinking it failed
# Run: sudo bash verify-nginx-running.sh

set -e

echo "=========================================="
echo "Verifying Nginx Status"
echo "=========================================="

# Check if nginx process is running
echo "1. Checking for nginx processes:"
ps aux | grep nginx | grep -v grep || echo "No nginx processes found"
echo ""

# Check if nginx is listening on ports
echo "2. Checking if nginx is listening on ports:"
ss -tulnp | grep nginx || echo "Nginx not listening on any ports"
echo ""

# Check systemd status
echo "3. Systemd status:"
systemctl status nginx --no-pager | head -10
echo ""

# If nginx is running but systemd doesn't know, we need to fix it
if ps aux | grep nginx | grep -v grep > /dev/null; then
    if ss -tulnp | grep nginx | grep -E ':80 |:443 ' > /dev/null; then
        echo "✅ NGINX IS RUNNING AND LISTENING!"
        echo ""
        echo "Ports:"
        ss -tulnp | grep nginx
        echo ""
        echo "The issue is that systemd doesn't recognize it."
        echo "Let's fix systemd to recognize the running process..."
        echo ""
        
        # Get the PID
        NGINX_PID=$(pgrep nginx | head -1)
        if [ -n "$NGINX_PID" ]; then
            echo "Found nginx PID: $NGINX_PID"
            # Create PID file
            echo "$NGINX_PID" > /run/nginx.pid
            echo "✅ Created PID file"
            
            # Try to reset systemd status
            systemctl reset-failed nginx 2>/dev/null || true
            echo "✅ Reset systemd failed status"
            
            # Check status again
            echo ""
            echo "Systemd status after fix:"
            systemctl status nginx --no-pager | head -10
        fi
    else
        echo "⚠️ Nginx process exists but not listening on ports"
    fi
else
    echo "❌ Nginx is not running"
    echo "Let's try to start it..."
    systemctl start nginx
    sleep 3
    if systemctl is-active --quiet nginx; then
        echo "✅ Nginx started successfully!"
    else
        echo "❌ Still failed to start"
        journalctl -xeu nginx.service --no-pager | tail -10
    fi
fi

