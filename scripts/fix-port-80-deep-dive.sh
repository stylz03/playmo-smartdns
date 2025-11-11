#!/bin/bash
# Deep dive into port 80 binding issue
# Run: sudo bash fix-port-80-deep-dive.sh

set -e

echo "=========================================="
echo "Deep Dive Port 80 Investigation"
echo "=========================================="

# Check for systemd socket units
echo "1. Checking for systemd socket units:"
systemctl list-units --type=socket | grep -i nginx || echo "No nginx socket units found"
echo ""

# Check iptables
echo "2. Checking iptables rules:"
iptables -L -n | grep -E '80|443' || echo "No iptables rules for ports 80/443"
echo ""

# Try to bind to port 80 with Python to see the actual error
echo "3. Testing port 80 binding with Python:"
python3 << 'PYTHON_TEST'
import socket
import errno

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', 80))
    s.listen(1)
    print("✅ Successfully bound to port 80")
    s.close()
except OSError as e:
    if e.errno == errno.EADDRINUSE:
        print(f"❌ Port 80 is in use: {e}")
    else:
        print(f"❌ Error binding to port 80: {e}")
PYTHON_TEST
echo ""

# Check if there's a listen directive issue in stream.conf
echo "4. Checking stream.conf listen directives:"
grep -n "listen" /etc/nginx/stream.conf
echo ""

# Maybe the issue is that we need to use a specific IP
# Let's check what IPs are available
echo "5. Checking available IP addresses:"
ip addr show | grep "inet " | grep -v "127.0.0.1"
echo ""

# Try modifying stream.conf to use a specific IP instead of 0.0.0.0
echo "6. Getting EC2 public IP:"
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo "")
if [ -n "$EC2_IP" ]; then
    echo "Local IP: $EC2_IP"
    echo ""
    echo "Trying to bind to $EC2_IP:80 instead of 0.0.0.0:80..."
    # Backup stream.conf
    cp /etc/nginx/stream.conf /etc/nginx/stream.conf.backup.$(date +%Y%m%d_%H%M%S)
    # Try changing 0.0.0.0 to the specific IP
    sed -i "s/listen 0.0.0.0:80/listen $EC2_IP:80/" /etc/nginx/stream.conf
    sed -i "s/listen 0.0.0.0:443/listen $EC2_IP:443/" /etc/nginx/stream.conf
    echo "✅ Modified stream.conf to use $EC2_IP instead of 0.0.0.0"
    echo ""
    echo "Testing configuration:"
    if nginx -t 2>&1 | grep -q "successful"; then
        echo "✅ Configuration is valid"
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
            ss -tulnp | grep nginx
            echo ""
            echo "✅ Success! Using specific IP instead of 0.0.0.0"
        else
            echo "❌ Still failed"
            # Restore backup
            mv /etc/nginx/stream.conf.backup.* /etc/nginx/stream.conf 2>/dev/null || true
            journalctl -xeu nginx.service --no-pager | tail -10
        fi
    else
        echo "❌ Configuration test failed"
        # Restore backup
        mv /etc/nginx/stream.conf.backup.* /etc/nginx/stream.conf 2>/dev/null || true
        nginx -t 2>&1
    fi
else
    echo "Could not get EC2 IP, trying different approach..."
    # Maybe try 127.0.0.1 or the default gateway IP
    echo "Trying with 127.0.0.1 (localhost only)..."
    cp /etc/nginx/stream.conf /etc/nginx/stream.conf.backup.$(date +%Y%m%d_%H%M%S)
    sed -i "s/listen 0.0.0.0:80/listen 127.0.0.1:80/" /etc/nginx/stream.conf
    sed -i "s/listen 0.0.0.0:443/listen 127.0.0.1:443/" /etc/nginx/stream.conf
    echo "⚠️ Changed to 127.0.0.1 - this will only work locally, not for external clients"
    echo "This is just a test to see if binding works"
    nginx -t && systemctl start nginx && sleep 2 && systemctl is-active --quiet nginx && echo "✅ Works with 127.0.0.1" || echo "❌ Still failed"
    # Restore
    mv /etc/nginx/stream.conf.backup.* /etc/nginx/stream.conf 2>/dev/null || true
fi

