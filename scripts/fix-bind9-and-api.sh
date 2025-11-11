#!/bin/bash
# Fix BIND9 to listen on all interfaces and check API service
# Run this on the EC2 instance: sudo bash fix-bind9-and-api.sh

set -e

echo "=== Fixing BIND9 and API Service ==="
echo ""

# 1. Fix BIND9 to listen on all interfaces
echo "1. Updating BIND9 configuration..."
cat > /etc/bind/named.conf.options <<'BIND9_OPTIONS'
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation auto;
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    query-source address *;
};
BIND9_OPTIONS

# Validate BIND9 config
echo "2. Validating BIND9 configuration..."
if named-checkconf; then
    echo "   ✅ BIND9 configuration is valid"
    systemctl restart bind9
    echo "   ✅ BIND9 restarted"
else
    echo "   ❌ BIND9 configuration is invalid!"
    exit 1
fi

# Check if BIND9 is listening on all interfaces
echo ""
echo "3. Checking BIND9 listening ports..."
sleep 2
if ss -tulnp | grep -E "named.*:53" | grep -q "0.0.0.0"; then
    echo "   ✅ BIND9 is listening on all interfaces (0.0.0.0:53)"
else
    echo "   ⚠️  BIND9 may not be listening on all interfaces"
    ss -tulnp | grep named | grep 53 || echo "   No BIND9 ports found"
fi

# 2. Check API service
echo ""
echo "4. Checking API service..."
if systemctl is-active --quiet playmo-smartdns-api; then
    echo "   ✅ API service is running"
    systemctl status playmo-smartdns-api --no-pager -l | head -10
else
    echo "   ❌ API service is not running"
    echo "   Checking service status..."
    systemctl status playmo-smartdns-api --no-pager -l | head -20 || true
    
    echo ""
    echo "   Attempting to start API service..."
    systemctl start playmo-smartdns-api || echo "   Failed to start"
    sleep 2
    
    if systemctl is-active --quiet playmo-smartdns-api; then
        echo "   ✅ API service started successfully"
    else
        echo "   ❌ API service failed to start"
        echo "   Checking logs..."
        journalctl -u playmo-smartdns-api -n 30 --no-pager || true
    fi
fi

# 3. Check if API is listening
echo ""
echo "5. Checking if API is listening on port 5000..."
if ss -tulnp | grep -q ":5000"; then
    echo "   ✅ Port 5000 is listening"
    ss -tulnp | grep 5000
else
    echo "   ❌ Port 5000 is not listening"
fi

# 4. Test API locally
echo ""
echo "6. Testing API locally..."
if curl -s http://localhost:5000/health > /dev/null; then
    echo "   ✅ API responds locally"
    curl -s http://localhost:5000/health
else
    echo "   ❌ API does not respond locally"
fi

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Test from your local machine:"
echo "  dig @3.151.46.11 netflix.com +short"
echo "  curl http://3.151.46.11:5000/health"

