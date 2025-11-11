#!/bin/bash
# Test streaming access and diagnose issues
# Run: sudo bash test-streaming-access.sh

set -e

echo "=========================================="
echo "Testing Streaming Access"
echo "=========================================="

EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "3.151.46.11")

echo "EC2 IP: $EC2_IP"
echo ""

# 1. Test DNS resolution
echo "1. Testing DNS Resolution:"
echo "netflix.com should resolve to $EC2_IP:"
NETFLIX_IP=$(dig @127.0.0.1 netflix.com +short | head -1)
if [ "$NETFLIX_IP" = "$EC2_IP" ]; then
    echo "✅ DNS correctly resolves to EC2 IP"
else
    echo "❌ DNS resolves to: $NETFLIX_IP (expected: $EC2_IP)"
fi

# 2. Test sniproxy forwarding
echo ""
echo "2. Testing Sniproxy Forwarding:"
echo "Attempting HTTPS connection through sniproxy..."
timeout 10 curl -v -k --resolve netflix.com:443:$EC2_IP https://netflix.com 2>&1 | grep -E "Connected|HTTP|TLS|error" | head -10 || echo "Connection test completed"

# 3. Check security group
echo ""
echo "3. Security Group Check:"
if command -v aws >/dev/null 2>&1; then
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "")
    if [ -n "$INSTANCE_ID" ]; then
        SG_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text --region us-east-2 2>/dev/null || echo "")
        if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
            echo "Security Group: $SG_ID"
            echo ""
            echo "Port 443 rules:"
            aws ec2 describe-security-groups --group-ids $SG_ID --query 'SecurityGroups[0].IpPermissions[?FromPort==`443` && IpProtocol==`tcp`]' --region us-east-2 --output json 2>/dev/null | python3 -m json.tool || echo "Could not query"
        fi
    fi
else
    echo "⚠️ AWS CLI not available"
fi

# 4. Check sniproxy logs for connection attempts
echo ""
echo "4. Recent Sniproxy Activity:"
journalctl -u sniproxy -n 30 --no-pager | grep -E "parse|connect|forward|error" || echo "No recent activity"

# 5. Test from external perspective
echo ""
echo "5. Testing External Access:"
echo "From your phone, you should be able to:"
echo "  - Resolve netflix.com → $EC2_IP ✅"
echo "  - Connect to $EC2_IP:443 (sniproxy) ✅"
echo "  - Sniproxy reads SNI 'netflix.com' ✅"
echo "  - Sniproxy forwards to real netflix.com ✅"
echo ""
echo "If streaming apps say 'no internet', possible issues:"
echo "1. Your phone's IP is blocked by security group"
echo "2. Apps use hardcoded IPs (bypass DNS)"
echo "3. Apps check IP geolocation"
echo "4. Sniproxy not forwarding correctly"
echo ""
echo "To whitelist your phone's IP, get your public IP and call:"
echo "  curl -X POST http://$EC2_IP:5000/api/ips/whitelist \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"ip\":\"YOUR_PHONE_IP\"}'"
echo ""
echo "Or check if ports 80/443 are open to 0.0.0.0/0 in security group."

