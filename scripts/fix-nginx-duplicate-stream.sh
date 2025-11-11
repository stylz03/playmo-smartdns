#!/bin/bash
# Fix duplicate stream blocks in Nginx
# Run: sudo bash fix-nginx-duplicate-stream.sh

set -e

echo "=========================================="
echo "Fixing Duplicate Stream Blocks"
echo "=========================================="

# Stop Nginx
systemctl stop nginx 2>/dev/null || true

# Backup nginx.conf
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Remove the stream block that's directly in nginx.conf
echo "Removing stream block from nginx.conf..."
# Find the line number where stream block starts
STREAM_START=$(grep -n "^stream {" /etc/nginx/nginx.conf | cut -d: -f1 | head -1 || echo "")

if [ -n "$STREAM_START" ]; then
    echo "Found stream block starting at line $STREAM_START"
    
    # Find the matching closing brace
    # Count braces to find the end
    TOTAL_LINES=$(wc -l < /etc/nginx/nginx.conf)
    BRACE_COUNT=0
    STREAM_END=""
    
    # Read from stream start to end of file
    IN_STREAM=false
    while IFS= read -r line; do
        if [ "$line" = "stream {" ]; then
            IN_STREAM=true
            BRACE_COUNT=1
        elif [ "$IN_STREAM" = true ]; then
            # Count braces
            OPEN=$(echo "$line" | grep -o '{' | wc -l)
            CLOSE=$(echo "$line" | grep -o '}' | wc -l)
            BRACE_COUNT=$((BRACE_COUNT + OPEN - CLOSE))
            
            if [ "$BRACE_COUNT" -eq 0 ]; then
                STREAM_END=$(grep -n "$line" /etc/nginx/nginx.conf | head -1 | cut -d: -f1)
                break
            fi
        fi
    done < /etc/nginx/nginx.conf
    
    if [ -n "$STREAM_END" ]; then
        echo "Removing lines $STREAM_START to $STREAM_END"
        sed -i "${STREAM_START},${STREAM_END}d" /etc/nginx/nginx.conf
        echo "✅ Removed stream block from nginx.conf"
    else
        echo "⚠️ Could not find end of stream block, trying alternative method..."
        # Alternative: remove from "stream {" to last "}" before include
        sed -i '/^stream {/,/^}$/d' /etc/nginx/nginx.conf
        echo "✅ Removed stream block (alternative method)"
    fi
else
    echo "✅ No stream block found directly in nginx.conf"
fi

# Ensure we have the include for /etc/nginx/stream.conf
if ! grep -q "include.*\/etc\/nginx\/stream.conf" /etc/nginx/nginx.conf; then
    echo "Adding include for /etc/nginx/stream.conf..."
    echo "" >> /etc/nginx/nginx.conf
    echo "include /etc/nginx/stream.conf;" >> /etc/nginx/nginx.conf
    echo "✅ Added include"
fi

# Ensure load_module is present
if ! grep -q "load_module.*ngx_stream_module" /etc/nginx/nginx.conf; then
    echo "Adding load_module directive..."
    sed -i '1i load_module /etc/nginx/modules/ngx_stream_module.so;' /etc/nginx/nginx.conf
fi

# Verify structure
echo ""
echo "Verifying nginx.conf structure..."
echo "--- Stream blocks in nginx.conf (should be 0) ---"
STREAM_COUNT=$(grep -c "^stream {" /etc/nginx/nginx.conf || echo "0")
echo "Found $STREAM_COUNT stream blocks directly in nginx.conf"
echo ""
echo "--- Include for stream.conf (should be 1) ---"
INCLUDE_COUNT=$(grep -c "include.*stream.conf" /etc/nginx/nginx.conf || echo "0")
echo "Found $INCLUDE_COUNT includes for stream.conf"
echo ""
echo "--- Last 5 lines of nginx.conf ---"
tail -5 /etc/nginx/nginx.conf

# Test Nginx configuration
echo ""
echo "Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Nginx configuration is valid"
    
    # Start Nginx
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
        echo "✅ Stream proxy is now active!"
    else
        echo "❌ Nginx failed to start"
        journalctl -xeu nginx.service --no-pager | tail -20
        exit 1
    fi
else
    echo "❌ Nginx configuration test failed:"
    nginx -t 2>&1
    exit 1
fi

