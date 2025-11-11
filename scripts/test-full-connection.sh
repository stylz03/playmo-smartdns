#!/bin/bash
# Test full connection through Nginx stream proxy
# Run: sudo bash test-full-connection.sh

set -e

EC2_IP="3.151.46.11"

echo "=========================================="
echo "Testing Full Connection Through Nginx"
echo "=========================================="

# Test 1: DNS Resolution
echo "1. Testing DNS Resolution:"
DNS_RESULT=$(dig +short netflix.com @$EC2_IP 2>/dev/null | head -1 || echo "")
if [ "$DNS_RESULT" = "$EC2_IP" ]; then
    echo "✅ DNS resolves to EC2 IP: $DNS_RESULT"
else
    echo "❌ DNS issue: $DNS_RESULT (expected: $EC2_IP)"
fi
echo ""

# Test 2: Port connectivity
echo "2. Testing Port Connectivity:"
if timeout 3 bash -c "echo > /dev/tcp/$EC2_IP/443" 2>/dev/null; then
    echo "✅ Port 443 is reachable"
else
    echo "❌ Port 443 not reachable (might be security group issue)"
fi

if timeout 3 bash -c "echo > /dev/tcp/$EC2_IP/80" 2>/dev/null; then
    echo "✅ Port 80 is reachable"
else
    echo "❌ Port 80 not reachable (might be security group issue)"
fi
echo ""

# Test 3: Full HTTPS connection
echo "3. Testing Full HTTPS Connection:"
echo "Connecting to netflix.com through Nginx..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --resolve netflix.com:443:$EC2_IP \
    --max-time 10 \
    https://netflix.com 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ HTTPS forwarding working! HTTP code: $HTTP_CODE"
elif [ "$HTTP_CODE" = "000" ]; then
    echo "❌ Connection failed (timeout or refused)"
else
    echo "⚠️ Got HTTP code: $HTTP_CODE (might be redirect or error page)"
fi
echo ""

# Test 4: Check Nginx access logs
echo "4. Checking Nginx Access Logs:"
if [ -f /var/log/nginx/access.log ]; then
    echo "Recent access log entries:"
    tail -5 /var/log/nginx/access.log 2>/dev/null || echo "No entries yet"
else
    echo "⚠️ Access log not found"
fi
echo ""

# Test 5: Check if security group allows 0.0.0.0/0
echo "5. Security Group Check:"
echo "For streaming to work, ports 80 and 443 must be open to 0.0.0.0/0"
echo "Or your phone's IP must be whitelisted."
echo ""
echo "To check your phone's public IP, visit: https://whatismyipaddress.com"
echo "Then whitelist it via:"
echo "  curl -X POST http://$EC2_IP:5000/api/ips/whitelist \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"ip\":\"YOUR_PHONE_IP\"}'"
echo ""

# Test 6: Verify stream.conf has resolver
echo "6. Verifying stream.conf:"
if grep -q "resolver" /etc/nginx/stream.conf; then
    echo "✅ Resolver found in stream.conf"
    grep "resolver" /etc/nginx/stream.conf | head -2
else
    echo "❌ No resolver in stream.conf"
fi
echo ""

echo "=========================================="
echo "Summary:"
echo "=========================================="
echo "If DNS and ports work but sites don't open on phone:"
echo "1. Check security group - ports 80/443 must be open to 0.0.0.0/0"
echo "2. Verify phone DNS is set to: $EC2_IP"
echo "3. Try whitelisting your phone's IP via the API"
echo "4. Note: Apps using QUIC/HTTP3 (UDP) won't work with Nginx stream (TCP only)"
echo ""

