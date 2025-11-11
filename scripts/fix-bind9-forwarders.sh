#!/bin/bash
# Fix BIND9 to forward non-streaming domains to Google/Cloudflare DNS
# Run: sudo bash fix-bind9-forwarders.sh

set -e

echo "=========================================="
echo "Fixing BIND9 forwarders for non-streaming domains"
echo "=========================================="

# Backup current config
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backed up named.conf.options"

# Update BIND9 options to include forwarders for non-streaming domains
cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
    query-source address *;
    
    // Forwarders for non-streaming domains (domains not in zone files)
    // Streaming domains are resolved from zone files to EC2 IP
    // All other domains are forwarded to Google and Cloudflare DNS
    forwarders {
        8.8.8.8;        // Google DNS
        8.8.4.4;        // Google DNS secondary
        1.1.1.1;        // Cloudflare DNS
        1.0.0.1;        // Cloudflare DNS secondary
    };
    forward only;      // Only use forwarders, don't do full recursive resolution
};
EOF

echo "✅ Updated named.conf.options with forwarders"

# Validate configuration
echo ""
echo "Validating BIND9 configuration..."
if named-checkconf; then
    echo "✅ BIND9 configuration is valid"
else
    echo "❌ BIND9 configuration has errors"
    named-checkconf
    exit 1
fi

# Reload BIND9
echo ""
echo "Reloading BIND9..."
systemctl reload bind9 || systemctl restart bind9
sleep 2

# Test DNS resolution
echo ""
echo "Testing DNS resolution..."
echo ""
echo "1. Testing streaming domain (should resolve to EC2 IP):"
dig @127.0.0.1 netflix.com +short || echo "❌ Failed"
echo ""
echo "2. Testing non-streaming domain (should resolve via forwarders):"
dig @127.0.0.1 google.com +short || echo "❌ Failed"
echo ""
echo "3. Testing another non-streaming domain:"
dig @127.0.0.1 github.com +short || echo "❌ Failed"
echo ""
echo "4. Testing from external (EC2 IP):"
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "3.151.46.11")
echo "Testing google.com from $EC2_IP:"
dig @$EC2_IP google.com +short || echo "❌ Failed"

echo ""
echo "=========================================="
echo "✅ BIND9 forwarders configured"
echo "=========================================="
echo ""
echo "Now BIND9 will:"
echo "- Resolve streaming domains from zone files → EC2 IP"
echo "- Forward all other domains to Google/Cloudflare DNS"
echo ""
echo "Your phone should now be able to resolve all domains!"

