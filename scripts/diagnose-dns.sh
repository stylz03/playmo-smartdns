#!/bin/bash
# Comprehensive DNS diagnostic script
# Run: sudo bash diagnose-dns.sh

set -e

echo "=========================================="
echo "DNS DIAGNOSTIC REPORT"
echo "=========================================="
echo ""

# 1. Check BIND9 status
echo "1. BIND9 Service Status:"
if systemctl is-active --quiet bind9; then
    echo "✅ BIND9 is running"
    systemctl status bind9 --no-pager -l | head -10
else
    echo "❌ BIND9 is NOT running"
    echo "Attempting to start..."
    systemctl start bind9 || echo "Failed to start BIND9"
    sleep 2
    if systemctl is-active --quiet bind9; then
        echo "✅ BIND9 started successfully"
    else
        echo "❌ BIND9 failed to start. Check logs:"
        journalctl -xeu bind9 --no-pager | tail -20
    fi
fi

echo ""
echo "2. DNS Port 53 Status:"
if ss -tulnp | grep -E ':53 '; then
    echo "✅ Port 53 is listening"
else
    echo "❌ Port 53 is NOT listening"
fi

echo ""
echo "3. BIND9 Configuration Test:"
if named-checkconf; then
    echo "✅ BIND9 configuration is valid"
else
    echo "❌ BIND9 configuration has errors"
    named-checkconf
fi

echo ""
echo "4. Local DNS Test:"
echo "Testing netflix.com:"
dig @127.0.0.1 netflix.com +short +timeout=2 || echo "❌ DNS query failed"
echo ""
echo "Testing disneyplus.com:"
dig @127.0.0.1 disneyplus.com +short +timeout=2 || echo "❌ DNS query failed"
echo ""
echo "Testing google.com (non-streaming):"
dig @127.0.0.1 google.com +short +timeout=2 || echo "❌ DNS query failed"

echo ""
echo "5. External DNS Test (from EC2):"
echo "Testing netflix.com from EC2 public IP:"
MY_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "unknown")
echo "EC2 Public IP: $MY_IP"
dig @$MY_IP netflix.com +short +timeout=2 || echo "❌ External DNS query failed"

echo ""
echo "6. Security Group Check:"
echo "Checking if port 53 is open in security group..."
# Try to get security group ID from instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "")
if [ -n "$INSTANCE_ID" ] && command -v aws >/dev/null 2>&1; then
    SG_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text --region us-east-2 2>/dev/null || echo "")
    if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
        echo "Security Group ID: $SG_ID"
        echo "DNS TCP rules:"
        aws ec2 describe-security-groups --group-ids $SG_ID --query 'SecurityGroups[0].IpPermissions[?FromPort==`53` && IpProtocol==`tcp`]' --region us-east-2 2>/dev/null || echo "Could not query"
        echo "DNS UDP rules:"
        aws ec2 describe-security-groups --group-ids $SG_ID --query 'SecurityGroups[0].IpPermissions[?FromPort==`53` && IpProtocol==`udp`]' --region us-east-2 2>/dev/null || echo "Could not query"
    else
        echo "⚠️ Could not determine security group ID"
    fi
else
    echo "⚠️ AWS CLI not available or instance ID not found"
fi

echo ""
echo "7. Zone Files Check:"
if [ -d /etc/bind/zones ]; then
    ZONE_COUNT=$(ls -1 /etc/bind/zones/* 2>/dev/null | wc -l)
    echo "✅ Zones directory exists with $ZONE_COUNT zone files"
    if [ "$ZONE_COUNT" -gt 0 ]; then
        echo "Sample zone files:"
        ls -lh /etc/bind/zones/ | head -5
    fi
else
    echo "❌ Zones directory does not exist"
fi

echo ""
echo "8. Named.conf.local Check:"
if [ -f /etc/bind/named.conf.local ]; then
    ZONE_DEFS=$(grep -c "zone.*{" /etc/bind/named.conf.local || echo "0")
    echo "✅ named.conf.local exists with $ZONE_DEFS zone definitions"
    echo "First few zones:"
    grep "zone.*{" /etc/bind/named.conf.local | head -5
else
    echo "❌ named.conf.local does not exist"
fi

echo ""
echo "=========================================="
echo "DIAGNOSTIC COMPLETE"
echo "=========================================="
echo ""
echo "Next steps if DNS is not working:"
echo "1. If BIND9 is not running: sudo systemctl start bind9"
echo "2. If port 53 is not listening: Check BIND9 logs"
echo "3. If security group blocks port 53: Whitelist your IP via API"
echo "4. If zone files missing: Run create-zone-files-sniproxy.sh"
echo ""
echo "To whitelist your IP, call the API:"
echo "curl -X POST http://$MY_IP:5000/api/ips/whitelist -H 'Content-Type: application/json' -d '{\"ip\":\"YOUR_IP\"}'"

