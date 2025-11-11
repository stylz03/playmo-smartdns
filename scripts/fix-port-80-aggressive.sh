#!/bin/bash
# Aggressive fix for port 80 binding issue
# Run: sudo bash fix-port-80-aggressive.sh

set -e

echo "=========================================="
echo "Aggressive Port 80 Fix"
echo "=========================================="

# Stop everything that might use port 80
echo "1. Stopping all services that might use port 80..."
systemctl stop nginx 2>/dev/null || true
systemctl stop sniproxy 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true
systemctl stop httpd 2>/dev/null || true
pkill -9 nginx 2>/dev/null || true
pkill -9 sniproxy 2>/dev/null || true
pkill -9 apache2 2>/dev/null || true
sleep 2

# Use multiple methods to find what's using port 80
echo ""
echo "2. Checking port 80 with multiple methods..."

# Method 1: lsof
echo "--- lsof ---"
lsof -i :80 2>/dev/null || echo "Nothing found with lsof"

# Method 2: netstat
echo "--- netstat ---"
netstat -tulnp 2>/dev/null | grep ':80 ' || echo "Nothing found with netstat"

# Method 3: ss
echo "--- ss ---"
ss -tulnp | grep ':80 ' || echo "Nothing found with ss"

# Method 4: fuser
echo "--- fuser ---"
fuser 80/tcp 2>/dev/null || echo "Nothing found with fuser"

# Method 5: Check /proc/net/tcp
echo "--- /proc/net/tcp ---"
grep ":0050 " /proc/net/tcp 2>/dev/null | head -5 || echo "Nothing found in /proc/net/tcp"

# Kill anything using port 80
echo ""
echo "3. Aggressively killing anything on port 80..."
fuser -k 80/tcp 2>/dev/null || true
sleep 2

# Check if there's a listen directive in nginx.conf http block that might conflict
echo ""
echo "4. Checking nginx.conf for listen directives..."
if grep -A 5 "^http {" /etc/nginx/nginx.conf | grep -q "listen.*80"; then
    echo "⚠️ Found listen 80 in http block - this might conflict"
    grep -A 10 "^http {" /etc/nginx/nginx.conf | grep "listen"
    echo ""
    echo "The http block shouldn't have a listen 80 if stream block handles it"
    echo "But this is usually fine - http and stream can both listen on different ports"
fi

# Check stream.conf for listen 80
echo ""
echo "5. Checking stream.conf for listen directives..."
grep "listen" /etc/nginx/stream.conf | head -5

# Wait for TIME_WAIT to clear
echo ""
echo "6. Waiting for TIME_WAIT sockets to clear..."
sleep 5

# Final check
echo ""
echo "7. Final port check..."
if lsof -i :80 2>/dev/null | grep -q LISTEN || ss -tulnp | grep -q ':80 '; then
    echo "⚠️ Port 80 is still in use:"
    lsof -i :80 2>/dev/null || ss -tulnp | grep ':80 '
    echo ""
    echo "Trying to identify the process more carefully..."
    # Get PID more carefully
    PID=$(lsof -ti :80 2>/dev/null | head -1 || ss -tulnp | grep ':80 ' | grep -oE 'pid=[0-9]+' | cut -d= -f2 | head -1 || echo "")
    if [ -n "$PID" ]; then
        echo "Found PID: $PID"
        ps -p "$PID" -o pid,ppid,cmd || echo "Process not found"
        echo "Killing PID $PID..."
        kill -9 "$PID" 2>/dev/null || true
        sleep 2
    fi
else
    echo "✅ Port 80 appears free"
fi

# Try starting nginx
echo ""
echo "8. Attempting to start Nginx..."
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
else
    echo "❌ Nginx still failed to start"
    echo ""
    echo "Checking if there's a conflict in the stream block..."
    # Check if stream.conf has listen 80 and http block also has it
    if grep -q "listen 80" /etc/nginx/stream.conf && grep -A 20 "^http {" /etc/nginx/nginx.conf | grep -q "listen.*80"; then
        echo "⚠️ Both stream and http blocks are trying to listen on port 80"
        echo "This is the issue! Stream block should handle 80, http block shouldn't"
    fi
    
    journalctl -xeu nginx.service --no-pager | tail -10
    exit 1
fi

