#!/bin/bash
# Comprehensive diagnostic for streaming sites not working
# Run: sudo bash diagnose-streaming-issues.sh

set -e

EC2_IP="3.151.46.11"

echo "=========================================="
echo "Diagnosing Streaming Site Issues"
echo "=========================================="

# 1. Check DNS resolution
echo "1. Testing DNS Resolution:"
echo "Testing netflix.com..."
DNS_RESULT=$(dig +short +timeout=3 netflix.com @$EC2_IP 2>/dev/null | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1 || echo "")
if [ "$DNS_RESULT" = "$EC2_IP" ]; then
    echo "✅ DNS correctly resolves netflix.com to EC2 IP: $DNS_RESULT"
else
    echo "❌ DNS resolution failed or wrong IP: $DNS_RESULT (expected: $EC2_IP)"
    echo "Checking BIND9 zone files..."
    if [ -f /etc/bind/zones/db.netflix_com ]; then
        echo "Zone file exists, checking content:"
        grep "IN A" /etc/bind/zones/db.netflix_com | head -3
    else
        echo "❌ Zone file not found: /etc/bind/zones/db.netflix_com"
    fi
fi
echo ""

# 2. Check Nginx stream proxy
echo "2. Checking Nginx Stream Proxy:"
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
    echo "Checking if listening on ports 80 and 443:"
    ss -tulnp | grep nginx | grep -E ':80 |:443 ' || echo "⚠️ Nginx not listening on 80/443"
else
    echo "❌ Nginx is not running"
    systemctl status nginx --no-pager | head -5
fi
echo ""

# 3. Check stream.conf
echo "3. Checking stream.conf:"
if [ -f /etc/nginx/stream.conf ]; then
    echo "✅ stream.conf exists"
    echo "Checking for netflix.com in config:"
    if grep -q "netflix" /etc/nginx/stream.conf; then
        echo "✅ netflix.com found in stream.conf"
        grep "netflix" /etc/nginx/stream.conf | head -2
    else
        echo "❌ netflix.com not found in stream.conf"
    fi
    echo "Checking listen directives:"
    grep "listen" /etc/nginx/stream.conf
else
    echo "❌ stream.conf not found"
fi
echo ""

# 4. Test HTTPS forwarding
echo "4. Testing HTTPS Forwarding:"
echo "Attempting to connect through Nginx stream proxy..."
CURL_OUTPUT=$(curl -v --resolve netflix.com:443:$EC2_IP https://netflix.com --max-time 10 2>&1 || true)
if echo "$CURL_OUTPUT" | grep -q "200 OK\|302 Found\|301 Moved"; then
    echo "✅ HTTPS forwarding appears to be working (received HTTP response)"
elif echo "$CURL_OUTPUT" | grep -q "Connection refused"; then
    echo "❌ Connection refused - Nginx not accepting connections"
elif echo "$CURL_OUTPUT" | grep -q "SSL\|TLS"; then
    echo "⚠️ TLS handshake issue - check Nginx stream config"
    echo "$CURL_OUTPUT" | grep -i "ssl\|tls\|error" | head -3
else
    echo "⚠️ Unknown issue with HTTPS forwarding"
    echo "$CURL_OUTPUT" | tail -5
fi
echo ""

# 5. Check security group (if AWS CLI available)
echo "5. Checking Security Group:"
if command -v aws >/dev/null 2>&1; then
    SG_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=playmo-smartdns-dns-only-ec2" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
        --output text --region us-east-2 2>/dev/null || echo "")
    if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
        echo "Security Group ID: $SG_ID"
        echo "Checking ingress rules for ports 80 and 443:"
        aws ec2 describe-security-groups \
            --group-ids "$SG_ID" \
            --query 'SecurityGroups[0].IpPermissions[?FromPort==`80` || FromPort==`443`]' \
            --region us-east-2 --output table 2>/dev/null || echo "Could not check security group rules"
    else
        echo "⚠️ Could not find security group"
    fi
else
    echo "⚠️ AWS CLI not available - cannot check security group"
    echo "Make sure ports 80 and 443 are open to 0.0.0.0/0 or your IP"
fi
echo ""

# 6. Check BIND9
echo "6. Checking BIND9:"
if systemctl is-active --quiet bind9; then
    echo "✅ BIND9 is running"
    echo "Testing local DNS resolution:"
    LOCAL_DNS=$(dig +short netflix.com @127.0.0.1 2>/dev/null | head -1 || echo "")
    if [ "$LOCAL_DNS" = "$EC2_IP" ]; then
        echo "✅ BIND9 correctly resolves netflix.com to EC2 IP locally"
    else
        echo "❌ BIND9 resolution issue: $LOCAL_DNS (expected: $EC2_IP)"
    fi
else
    echo "❌ BIND9 is not running"
    systemctl status bind9 --no-pager | head -5
fi
echo ""

# 7. Get user's public IP for whitelisting
echo "7. Your Public IP (for security group whitelisting):"
USER_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "Could not determine")
echo "Your IP: $USER_IP"
echo ""
echo "If streaming sites don't work, you may need to whitelist this IP:"
echo "  curl -X POST http://$EC2_IP:5000/api/ips/whitelist \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"ip\":\"$USER_IP\"}'"
echo ""

# 8. Summary
echo "=========================================="
echo "Summary:"
echo "=========================================="
echo "DNS Resolution: $([ "$DNS_RESULT" = "$EC2_IP" ] && echo "✅ Working" || echo "❌ Failed")"
echo "Nginx Status: $(systemctl is-active --quiet nginx && echo "✅ Running" || echo "❌ Not Running")"
echo "BIND9 Status: $(systemctl is-active --quiet bind9 && echo "✅ Running" || echo "❌ Not Running")"
echo ""
echo "Common issues:"
echo "1. DNS not resolving to EC2 IP → Check BIND9 zone files"
echo "2. Security group blocking your IP → Whitelist your IP via API"
echo "3. Nginx not forwarding correctly → Check stream.conf"
echo "4. Apps using QUIC/HTTP3 (UDP) → Nginx stream only handles TCP"
echo ""

