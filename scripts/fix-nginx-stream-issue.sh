#!/bin/bash
# Fix Nginx - Python can bind but Nginx can't, so it's an Nginx-specific issue
# Run: sudo bash fix-nginx-stream-issue.sh

set -e

echo "=========================================="
echo "Fixing Nginx Stream Issue"
echo "=========================================="

# Check Nginx error log for the actual error
echo "1. Checking Nginx error log:"
tail -30 /var/log/nginx/error.log 2>/dev/null || echo "No error log found"
echo ""

# Try starting nginx with verbose output
echo "2. Testing Nginx startup with verbose output:"
systemctl stop nginx 2>/dev/null || true
pkill nginx 2>/dev/null || true
sleep 2

# Try starting nginx directly and capture all output
echo "Starting nginx directly to see exact error:"
/usr/sbin/nginx -g 'daemon off;' 2>&1 | head -20 &
NGINX_PID=$!
sleep 3

if kill -0 $NGINX_PID 2>/dev/null; then
    echo "✅ Nginx started successfully!"
    kill $NGINX_PID 2>/dev/null || true
    sleep 1
else
    echo "❌ Nginx failed to start"
    wait $NGINX_PID 2>&1 || true
fi
echo ""

# The issue might be that stream block is trying to bind before something is ready
# Or there's a conflict in the stream configuration itself
echo "3. Checking stream.conf for potential issues:"
# Check if there are any syntax issues or conflicts
grep -n "listen\|server\|map" /etc/nginx/stream.conf | head -20
echo ""

# Try temporarily disabling the stream block to see if that's the issue
echo "4. Testing if stream block is causing the issue..."
# Backup stream.conf
cp /etc/nginx/stream.conf /etc/nginx/stream.conf.backup.$(date +%Y%m%d_%H%M%S)

# Comment out the stream block include in nginx.conf
sed -i 's|include /etc/nginx/stream.conf;|# include /etc/nginx/stream.conf;|' /etc/nginx/nginx.conf

echo "Temporarily disabled stream block, testing nginx startup..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Configuration valid without stream block"
    systemctl start nginx
    sleep 3
    if systemctl is-active --quiet nginx; then
        echo "✅ Nginx starts without stream block!"
        echo "The issue is with the stream block configuration"
        systemctl stop nginx
        # Restore stream.conf include
        sed -i 's|# include /etc/nginx/stream.conf;|include /etc/nginx/stream.conf;|' /etc/nginx/nginx.conf
        
        # Try fixing stream.conf - maybe the issue is with the resolver or proxy_pass
        echo ""
        echo "5. Fixing stream.conf - trying without resolver in server blocks..."
        # The resolver might be causing issues - let's try removing it
        sed -i '/resolver/d' /etc/nginx/stream.conf
        sed -i '/resolver_timeout/d' /etc/nginx/stream.conf
        
        # Test again
        if nginx -t 2>&1 | grep -q "successful"; then
            echo "✅ Configuration valid after removing resolver"
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
                ss -tulnp | grep nginx
                echo ""
                echo "✅ Success! Removed resolver from stream block"
            else
                echo "❌ Still failed after removing resolver"
                # Restore backup
                mv /etc/nginx/stream.conf.backup.* /etc/nginx/stream.conf 2>/dev/null || true
                journalctl -xeu nginx.service --no-pager | tail -10
            fi
        else
            echo "❌ Configuration invalid after removing resolver"
            # Restore backup
            mv /etc/nginx/stream.conf.backup.* /etc/nginx/stream.conf 2>/dev/null || true
            nginx -t 2>&1
        fi
    else
        echo "❌ Nginx still fails even without stream block"
        # Restore
        sed -i 's|# include /etc/nginx/stream.conf;|include /etc/nginx/stream.conf;|' /etc/nginx/nginx.conf
        journalctl -xeu nginx.service --no-pager | tail -10
    fi
else
    echo "❌ Configuration invalid even without stream block"
    # Restore
    sed -i 's|# include /etc/nginx/stream.conf;|include /etc/nginx/stream.conf;|' /etc/nginx/nginx.conf
    nginx -t 2>&1
fi

