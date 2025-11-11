#!/bin/bash
# Fix Squid proxy configuration
# Run this on EC2: sudo bash fix-squid-proxy.sh

set -e

echo "=== Fixing Squid Proxy Configuration ==="

# Backup current config
cp /etc/squid/squid.conf /etc/squid/squid.conf.backup.$(date +%Y%m%d_%H%M%S)

# Create new Squid configuration that allows all traffic for whitelisted IPs
cat > /etc/squid/squid.conf <<'SQUID_CONF'
# Squid configuration for SmartDNS proxy
# Allow all traffic for whitelisted IPs, deny others

http_port 3128

# ACL for whitelisted IPs (will be updated dynamically)
acl whitelisted_ips src "/etc/squid/whitelisted-ips.txt"

# Allow whitelisted IPs to use proxy for ALL domains
http_access allow whitelisted_ips

# Deny all other proxy requests
http_access deny all

# Forward to destination (transparent proxy)
forwarded_for on
via off

# Cache settings (minimal caching for streaming)
cache deny all
maximum_object_size 0 KB

# Logging
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log

# DNS settings (use local BIND9)
dns_nameservers 127.0.0.1

# Performance
max_filedescriptors 4096

# Allow CONNECT method for HTTPS
acl SSL_ports port 443
acl CONNECT method CONNECT
http_access allow CONNECT whitelisted_ips SSL_ports
SQUID_CONF

# Create/update whitelisted IPs file with current IPs from security group
echo "Updating whitelisted IPs..."
SECURITY_GROUP_ID=$(curl -s http://169.254.169.254/latest/meta-data/security-groups 2>/dev/null | head -1 || echo "")
if [ -z "$SECURITY_GROUP_ID" ]; then
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    SECURITY_GROUP_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text --region us-east-2 2>/dev/null || echo "sg-0a9d5b82bfd5fe829")
fi

# Get whitelisted IPs from security group (port 3128)
echo "Getting whitelisted IPs from security group: $SECURITY_GROUP_ID"
aws ec2 describe-security-groups \
    --group-ids "$SECURITY_GROUP_ID" \
    --query 'SecurityGroups[0].IpPermissions[?FromPort==`3128`].IpRanges[*].CidrIp' \
    --output text --region us-east-2 2>/dev/null | tr '\t' '\n' | sed 's/\/32$//' > /tmp/whitelisted-ips.txt || echo "102.32.126.36" > /tmp/whitelisted-ips.txt

# If file is empty, add at least the known IP
if [ ! -s /tmp/whitelisted-ips.txt ]; then
    echo "102.32.126.36" > /tmp/whitelisted-ips.txt
fi

mv /tmp/whitelisted-ips.txt /etc/squid/whitelisted-ips.txt
chmod 644 /etc/squid/whitelisted-ips.txt

echo "Whitelisted IPs:"
cat /etc/squid/whitelisted-ips.txt

# Test Squid configuration
echo ""
echo "Testing Squid configuration..."
if squid -k parse > /dev/null 2>&1; then
    echo "✅ Squid configuration is valid"
else
    echo "❌ Squid configuration has errors:"
    squid -k parse
    exit 1
fi

# Restart Squid
echo ""
echo "Restarting Squid..."
systemctl restart squid
sleep 2

# Check status
echo ""
echo "Squid status:"
systemctl status squid --no-pager -l | head -15

# Check if listening
echo ""
echo "Checking if Squid is listening on port 3128:"
ss -tulnp | grep 3128 || echo "⚠️  Squid not listening on 3128"

echo ""
echo "=== Squid Fix Complete ==="
echo ""
echo "Test proxy from your phone:"
echo "  Proxy: 3.151.46.11:3128"
echo ""
echo "Note: Make sure your IP (102.32.126.36) is in /etc/squid/whitelisted-ips.txt"

