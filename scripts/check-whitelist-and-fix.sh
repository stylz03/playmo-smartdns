#!/bin/bash
# Check if phone IP is whitelisted and fix if needed
# Run: sudo bash check-whitelist-and-fix.sh

set -e

echo "=========================================="
echo "Checking IP Whitelisting for Streaming"
echo "=========================================="

# Get EC2 instance info
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "")
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "3.151.46.11")

echo "EC2 Instance ID: $INSTANCE_ID"
echo "EC2 Public IP: $EC2_IP"
echo ""

# Check security group rules
if [ -n "$INSTANCE_ID" ] && command -v aws >/dev/null 2>&1; then
    echo "Checking security group rules..."
    SG_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text --region us-east-2 2>/dev/null || echo "")
    
    if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
        echo "Security Group ID: $SG_ID"
        echo ""
        echo "Port 80 (HTTP) rules:"
        aws ec2 describe-security-groups --group-ids $SG_ID --query 'SecurityGroups[0].IpPermissions[?FromPort==`80` && IpProtocol==`tcp`]' --region us-east-2 --output json 2>/dev/null || echo "Could not query"
        echo ""
        echo "Port 443 (HTTPS) rules:"
        aws ec2 describe-security-groups --group-ids $SG_ID --query 'SecurityGroups[0].IpPermissions[?FromPort==`443` && IpProtocol==`tcp`]' --region us-east-2 --output json 2>/dev/null || echo "Could not query"
    else
        echo "⚠️ Could not determine security group ID"
    fi
else
    echo "⚠️ AWS CLI not available or instance ID not found"
fi

echo ""
echo "=========================================="
echo "SOLUTION: Whitelist Your Phone's IP"
echo "=========================================="
echo ""
echo "Your phone's IP needs to be whitelisted for ports 80/443."
echo ""
echo "Option 1: Use the API to whitelist (recommended):"
echo "  Get your phone's public IP (check on your phone or use a website)"
echo "  Then call:"
echo "  curl -X POST http://$EC2_IP:5000/api/ips/whitelist \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"ip\":\"YOUR_PHONE_IP\"}'"
echo ""
echo "Option 2: Temporarily open ports 80/443 to all (less secure):"
echo "  This will allow anyone to access, but useful for testing"
echo ""
echo "Option 3: Check if Lambda whitelist URL is configured:"
echo "  curl http://$EC2_IP:5000/health"
echo ""

# Check API health
echo "Checking API health..."
if curl -s http://localhost:5000/health >/dev/null 2>&1; then
    echo "✅ API is running"
    API_HEALTH=$(curl -s http://localhost:5000/health)
    echo "$API_HEALTH" | python3 -m json.tool 2>/dev/null || echo "$API_HEALTH"
else
    echo "❌ API is not running or not accessible"
fi

echo ""
echo "=========================================="
echo "Quick Test: Check if ports are accessible"
echo "=========================================="
echo ""
echo "From your phone, try to access:"
echo "  http://$EC2_IP (should show connection, even if error)"
echo "  https://$EC2_IP (should show connection, even if error)"
echo ""
echo "If you get 'connection refused' or timeout, your IP is blocked."
echo "If you get any response (even an error), the port is open."

