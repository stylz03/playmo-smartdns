#!/bin/bash
# Fix port 80 conflict - find and stop what's using it
# Run: sudo bash fix-port-80-conflict.sh

set -e

echo "=========================================="
echo "Fixing Port 80 Conflict"
echo "=========================================="

# Check what's using port 80
echo "Checking what's using port 80..."
PORT_80_PROCESS=$(lsof -i :80 2>/dev/null | tail -n +2 || echo "")
if [ -z "$PORT_80_PROCESS" ]; then
    # Try with ss
    PORT_80_PROCESS=$(ss -tulnp | grep ':80 ' || echo "")
fi

if [ -n "$PORT_80_PROCESS" ]; then
    echo "Found process using port 80:"
    echo "$PORT_80_PROCESS"
    echo ""
    
    # Extract PID
    PID=$(echo "$PORT_80_PROCESS" | awk '{print $2}' | grep -oE '[0-9]+' | head -1 || echo "")
    if [ -z "$PID" ]; then
        # Try different method
        PID=$(lsof -ti :80 2>/dev/null | head -1 || echo "")
    fi
    
    if [ -n "$PID" ]; then
        echo "Process ID: $PID"
        echo "Process details:"
        ps -p "$PID" -o pid,cmd || echo "Process not found"
        echo ""
        
        # Check if it's sniproxy
        if ps -p "$PID" -o cmd | grep -q sniproxy; then
            echo "⚠️ Found sniproxy using port 80"
            echo "Stopping sniproxy..."
            systemctl stop sniproxy 2>/dev/null || true
            systemctl disable sniproxy 2>/dev/null || true
            kill -9 "$PID" 2>/dev/null || true
            echo "✅ Stopped sniproxy"
        # Check if it's apache2
        elif ps -p "$PID" -o cmd | grep -q apache; then
            echo "⚠️ Found Apache using port 80"
            echo "Stopping Apache..."
            systemctl stop apache2 2>/dev/null || true
            kill -9 "$PID" 2>/dev/null || true
            echo "✅ Stopped Apache"
        # Check if it's another nginx
        elif ps -p "$PID" -o cmd | grep -q nginx; then
            echo "⚠️ Found another nginx process using port 80"
            echo "Killing nginx process..."
            kill -9 "$PID" 2>/dev/null || true
            systemctl stop nginx 2>/dev/null || true
            echo "✅ Stopped nginx"
        else
            echo "⚠️ Unknown process using port 80"
            echo "Killing process $PID..."
            kill -9 "$PID" 2>/dev/null || true
            echo "✅ Killed process"
        fi
    else
        echo "⚠️ Could not determine PID, trying to stop common services..."
        systemctl stop sniproxy 2>/dev/null || true
        systemctl stop apache2 2>/dev/null || true
        systemctl stop nginx 2>/dev/null || true
        pkill -9 sniproxy 2>/dev/null || true
        pkill -9 apache2 2>/dev/null || true
        echo "✅ Stopped common services"
    fi
else
    echo "✅ Port 80 appears to be free"
fi

# Wait a moment for port to be released
sleep 2

# Verify port 80 is free
echo ""
echo "Verifying port 80 is free..."
if lsof -i :80 2>/dev/null | grep -q LISTEN || ss -tulnp | grep -q ':80 '; then
    echo "⚠️ Port 80 is still in use:"
    lsof -i :80 2>/dev/null || ss -tulnp | grep ':80 '
    echo ""
    echo "Trying more aggressive cleanup..."
    fuser -k 80/tcp 2>/dev/null || true
    sleep 2
else
    echo "✅ Port 80 is now free"
fi

# Also check port 443
echo ""
echo "Checking port 443..."
if lsof -i :443 2>/dev/null | grep -q LISTEN || ss -tulnp | grep -q ':443 '; then
    echo "⚠️ Port 443 is in use:"
    lsof -i :443 2>/dev/null || ss -tulnp | grep ':443 '
    PID_443=$(lsof -ti :443 2>/dev/null | head -1 || echo "")
    if [ -n "$PID_443" ]; then
        if ps -p "$PID_443" -o cmd | grep -q sniproxy; then
            echo "Stopping sniproxy on port 443..."
            systemctl stop sniproxy 2>/dev/null || true
            kill -9 "$PID_443" 2>/dev/null || true
        fi
    fi
else
    echo "✅ Port 443 is free"
fi

# Now try to start Nginx
echo ""
echo "Attempting to start Nginx..."
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
    echo "✅ Port conflict resolved!"
else
    echo "❌ Nginx still failed to start"
    journalctl -xeu nginx.service --no-pager | tail -10
    exit 1
fi

