#!/bin/bash
# Setup BIND9 DNS server on EC2 instance
# Run this on the EC2 instance

set -e

echo "=== Setting up BIND9 DNS Server ==="

# Step 1: Install BIND9
echo "Installing BIND9..."
sudo apt-get update -y
sudo apt-get install -y bind9 bind9utils bind9-dnsutils

# Step 2: Configure BIND9 global options
echo "Configuring BIND9..."
sudo tee /etc/bind/named.conf.options > /dev/null <<'EOF'
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

# Step 3: Get streaming domains from services.json
# We'll create a basic forward zone configuration
echo "Configuring forward zones..."

# Create named.conf.local with forward zones
sudo tee /etc/bind/named.conf.local > /dev/null <<'FORWARDZONES'
zone "aetv.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "amazonvideo.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "amcplus.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "bamgrid.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "britbox.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "crackle.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "dazn.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "directv.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "discoveryplus.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "dishanywhere.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "disneyplus.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "espn.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "espnplus.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "flosports.tv" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "fubo.tv" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "hbomax.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "hgtv.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "hulu.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "magellantv.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "max.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "mgmplus.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "netflix.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "nflxvideo.net" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "paramount.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "paramountplus.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "peacocktv.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "philo.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "primevideo.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "roku.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "sling.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "tbs.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "tntdrama.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "tubi.tv" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "tv.apple.com" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};

zone "xumo.tv" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};
FORWARDZONES

# Step 4: Enable and start BIND9
echo "Starting BIND9 service..."
sudo systemctl enable bind9
sudo systemctl restart bind9

# Step 5: Check status
echo ""
echo "Checking BIND9 status..."
sudo systemctl status bind9 --no-pager | head -10

# Step 6: Check if port 53 is listening
echo ""
echo "Checking if port 53 is listening..."
sudo ss -tulnp | grep 53 || echo "⚠️ Port 53 not listening yet"

# Step 7: Test DNS
echo ""
echo "Testing DNS resolution..."
echo "Testing netflix.com:"
dig @127.0.0.1 netflix.com +short || echo "❌ DNS test failed"

echo ""
echo "=== BIND9 Setup Complete ==="
echo "Your DNS server IP: 3.151.46.11"
echo "Configure this IP as your DNS server on your devices!"

