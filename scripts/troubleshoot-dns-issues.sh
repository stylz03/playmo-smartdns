#!/bin/bash
# Troubleshoot DNS issues on EC2
# Run this on the EC2 instance: sudo bash troubleshoot-dns-issues.sh

echo "=== DNS Troubleshooting ==="
echo ""

# 1. Check BIND9 status
echo "1. Checking BIND9 status..."
systemctl status bind9 --no-pager -l | head -10

# 2. Check BIND9 logs for errors
echo ""
echo "2. Recent BIND9 logs (last 30 lines)..."
journalctl -u bind9 -n 30 --no-pager | tail -20

# 3. Check what BIND9 is listening on
echo ""
echo "3. BIND9 listening ports..."
ss -tulnp | grep named | grep 53

# 4. Test DNS resolution locally
echo ""
echo "4. Testing DNS resolution locally..."
echo "Testing netflix.com:"
dig @127.0.0.1 netflix.com +short

echo ""
echo "Testing google.com:"
dig @127.0.0.1 google.com +short

echo ""
echo "Testing a non-streaming domain:"
dig @127.0.0.1 example.com +short

# 5. Check BIND9 configuration
echo ""
echo "5. Checking BIND9 configuration..."
echo "named.conf.options:"
cat /etc/bind/named.conf.options | grep -E "listen-on|allow-query|allow-recursion|recursion"

echo ""
echo "Checking for any zone issues..."
named-checkconf 2>&1 | head -20

# 6. Check if there are any denied queries
echo ""
echo "6. Checking for denied queries in logs..."
journalctl -u bind9 --since "10 minutes ago" | grep -i "denied" | tail -10

# 7. Test recursive resolution
echo ""
echo "7. Testing recursive resolution..."
echo "Querying root nameserver for google.com:"
dig @8.8.8.8 google.com +short

echo ""
echo "=== Troubleshooting Complete ==="
echo ""
echo "Common issues:"
echo "- If 'denied' appears in logs, check allow-query and allow-recursion settings"
echo "- If no response, check if BIND9 is listening on 0.0.0.0:53"
echo "- If some domains work but others don't, check zone configuration"

