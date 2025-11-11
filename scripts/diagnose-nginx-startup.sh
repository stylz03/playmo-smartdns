#!/bin/bash
# Diagnose why Nginx isn't starting despite valid config
# Run: sudo bash diagnose-nginx-startup.sh

set -e

echo "=========================================="
echo "Diagnosing Nginx Startup Issue"
echo "=========================================="

# Check service status
echo "1. Checking Nginx service status..."
systemctl status nginx --no-pager -l | head -20
echo ""

# Check recent logs
echo "2. Recent Nginx logs:"
journalctl -xeu nginx.service --no-pager | tail -30
echo ""

# Check if ports are in use
echo "3. Checking for port conflicts:"
ss -tulnp | grep -E ':80 |:443 ' || echo "Ports 80 and 443 are available"
echo ""

# Check if nginx process is running
echo "4. Checking for nginx processes:"
ps aux | grep nginx | grep -v grep || echo "No nginx processes found"
echo ""

# Check file permissions
echo "5. Checking file permissions:"
ls -la /etc/nginx/nginx.conf
ls -la /etc/nginx/stream.conf
ls -la /etc/nginx/modules/ngx_stream_module.so 2>/dev/null || echo "Module file not found"
echo ""

# Try starting manually to see error
echo "6. Attempting manual start to see error:"
/usr/sbin/nginx -t
echo ""
echo "Trying to start nginx in foreground (will show error then exit):"
timeout 2 /usr/sbin/nginx -g "daemon off;" 2>&1 || true
echo ""

# Check systemd service file
echo "7. Checking systemd service file:"
cat /lib/systemd/system/nginx.service 2>/dev/null || cat /etc/systemd/system/nginx.service 2>/dev/null || echo "Service file not found"
echo ""

echo "=========================================="
echo "Diagnosis Complete"
echo "=========================================="

