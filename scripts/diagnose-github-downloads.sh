#!/bin/bash
# Diagnose GitHub download issues on EC2

echo "=== Diagnosing GitHub Download Issues ==="
echo ""

# 1. Check network connectivity
echo "1. Testing GitHub connectivity..."
if curl -s -I https://github.com | head -1 | grep -q "200\|301\|302"; then
    echo "✅ GitHub is reachable"
else
    echo "❌ Cannot reach GitHub"
fi

# 2. Test raw.githubusercontent.com
echo ""
echo "2. Testing raw.githubusercontent.com..."
if curl -s -I https://raw.githubusercontent.com | head -1 | grep -q "200\|301\|302\|403"; then
    echo "✅ raw.githubusercontent.com is reachable"
else
    echo "❌ Cannot reach raw.githubusercontent.com"
fi

# 3. Test specific file download
echo ""
echo "3. Testing specific file download..."
RESPONSE=$(curl -s -w "\n%{http_code}" https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json 2>&1)
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ File download successful (HTTP $HTTP_CODE)"
    echo "   File size: $(echo "$BODY" | wc -c) bytes"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "❌ File not found (HTTP 404)"
    echo "   The file may not exist or path is wrong"
elif [ "$HTTP_CODE" = "403" ]; then
    echo "❌ Access forbidden (HTTP 403)"
    echo "   Possible rate limiting or IP blocking"
else
    echo "⚠️ Unexpected response (HTTP $HTTP_CODE)"
    echo "   Response: $(echo "$BODY" | head -5)"
fi

# 4. Check DNS resolution
echo ""
echo "4. Testing DNS resolution..."
if nslookup raw.githubusercontent.com >/dev/null 2>&1; then
    echo "✅ DNS resolution works"
    nslookup raw.githubusercontent.com | grep -A 2 "Name:"
else
    echo "❌ DNS resolution failed"
fi

# 5. Check outbound connectivity
echo ""
echo "5. Testing outbound HTTPS connectivity..."
if timeout 5 curl -s https://www.google.com >/dev/null 2>&1; then
    echo "✅ Outbound HTTPS works"
else
    echo "❌ Outbound HTTPS blocked or slow"
fi

# 6. Check security group (if AWS CLI available)
echo ""
echo "6. Checking security group egress rules..."
if command -v aws >/dev/null 2>&1; then
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
    if [ -n "$INSTANCE_ID" ]; then
        SG_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text 2>/dev/null)
        if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
            echo "   Security Group: $SG_ID"
            aws ec2 describe-security-groups --group-ids "$SG_ID" --query 'SecurityGroups[0].IpPermissionsEgress[*].[IpProtocol,FromPort,ToPort]' --output table 2>/dev/null || echo "   Could not query security group"
        fi
    fi
else
    echo "   AWS CLI not available"
fi

# 7. Test with different methods
echo ""
echo "7. Testing alternative download methods..."
echo "   Method 1: curl with timeout..."
if timeout 10 curl -s -f https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json -o /tmp/test-download.json 2>&1; then
    if [ -f /tmp/test-download.json ] && [ -s /tmp/test-download.json ]; then
        echo "   ✅ curl download successful"
        rm -f /tmp/test-download.json
    else
        echo "   ❌ curl download failed or empty"
    fi
else
    echo "   ❌ curl download failed or timed out"
fi

echo ""
echo "=== Diagnosis Complete ==="
echo ""
echo "Common fixes:"
echo "1. If 403/rate limiting: Wait a few minutes or use GitHub token"
echo "2. If 404: Check file path and branch name"
echo "3. If timeout: Check security group egress rules"
echo "4. If DNS fails: Check VPC DNS settings"

