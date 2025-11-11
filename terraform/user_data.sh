#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get upgrade -y
apt-get install -y bind9 bind9utils bind9-dnsutils unattended-upgrades fail2ban squid

# Bind9 global options (optimized for US-based SmartDNS)
cat > /etc/bind/named.conf.options <<'EOF'
${NAMED_CONF_OPTIONS}
EOF

# Create zones directory for static A records
mkdir -p /etc/bind/zones

# Create zone files for domains with static US CDN IPs
if [ -n "${ZONE_FILES}" ] && [ "${ZONE_FILES}" != "null" ]; then
    echo "Creating zone files for static US CDN IPs..."
    # Write JSON to temp file, then parse it
    echo '${ZONE_FILES}' > /tmp/zone_files.json
    python3 <<'PYTHON_SCRIPT'
import json
import os
import sys

try:
    with open('/tmp/zone_files.json', 'r') as f:
        zone_files = json.load(f)
    
    for domain, zone_content in zone_files.items():
        if zone_content:
            zone_file = f"/etc/bind/zones/db.{domain.replace('.', '_')}"
            with open(zone_file, 'w') as f:
                f.write(zone_content)
            os.chmod(zone_file, 0o644)
            print(f"Created zone file: {zone_file} for {domain}")
    
    os.remove('/tmp/zone_files.json')
except Exception as e:
    print(f"Error creating zone files: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT
fi

# Inject selective forward zones and static zones
cat > /etc/bind/named.conf.local <<'EOF'
${NAMED_CONF_LOCAL}
EOF

# Validate configuration before restarting
if named-checkconf; then
    systemctl enable bind9
    systemctl restart bind9
    echo "BIND9 restarted successfully"
else
    echo "ERROR: BIND9 configuration is invalid!"
    exit 1
fi

# Install and configure Squid proxy for streaming domains
echo "Configuring Squid proxy..."
# Backup default config
cp /etc/squid/squid.conf /etc/squid/squid.conf.backup

# Create streaming domains list
cat > /etc/squid/streaming-domains.txt <<'STREAMING_DOMAINS'
netflix.com
nflxvideo.net
hulu.com
disneyplus.com
bamgrid.com
hbomax.com
max.com
peacocktv.com
paramountplus.com
paramount.com
espn.com
espnplus.com
primevideo.com
amazonvideo.com
tv.apple.com
sling.com
discoveryplus.com
tubi.tv
crackle.com
roku.com
tntdrama.com
tbs.com
flosports.tv
magellantv.com
aetv.com
directv.com
britbox.com
dazn.com
fubo.tv
philo.com
dishanywhere.com
xumo.tv
hgtv.com
amcplus.com
mgmplus.com
STREAMING_DOMAINS

# Create Squid configuration
cat > /etc/squid/squid.conf <<'SQUID_CONF'
# Squid configuration for SmartDNS proxy
# Only proxy streaming domains, allow direct access for others

http_port 3128

# ACL for streaming domains
acl streaming_domains dstdomain "/etc/squid/streaming-domains.txt"

# ACL for whitelisted IPs (will be updated dynamically)
acl whitelisted_ips src "/etc/squid/whitelisted-ips.txt"

# Allow whitelisted IPs to use proxy for streaming domains
http_access allow whitelisted_ips streaming_domains

# Deny all other proxy requests
http_access deny all

# Allow direct access (no proxy) for non-streaming domains
# This is handled by client configuration - clients only use proxy for streaming

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
SQUID_CONF

# Create empty whitelisted IPs file (will be updated by API)
touch /etc/squid/whitelisted-ips.txt
chmod 644 /etc/squid/whitelisted-ips.txt

# Create script to update whitelisted IPs
cat > /usr/local/bin/update-squid-acl.sh <<'UPDATE_SCRIPT'
#!/bin/bash
# Update Squid ACL with whitelisted IPs from security group
# This script is called by the API when IPs are whitelisted

SECURITY_GROUP_ID="${1:-}"
if [ -z "$SECURITY_GROUP_ID" ]; then
    echo "Usage: $0 <security-group-id>"
    exit 1
fi

# Get whitelisted IPs from security group (port 3128)
aws ec2 describe-security-groups \
    --group-ids "$SECURITY_GROUP_ID" \
    --query 'SecurityGroups[0].IpPermissions[?FromPort==`3128`].IpRanges[*].CidrIp' \
    --output text | tr '\t' '\n' | sed 's/\/32$//' > /tmp/whitelisted-ips.txt

# Update Squid ACL file
mv /tmp/whitelisted-ips.txt /etc/squid/whitelisted-ips.txt
chmod 644 /etc/squid/whitelisted-ips.txt

# Reload Squid configuration
squid -k reconfigure

echo "Updated Squid ACL with whitelisted IPs"
UPDATE_SCRIPT

chmod +x /usr/local/bin/update-squid-acl.sh

# Enable and start Squid
systemctl enable squid
systemctl start squid

echo "✅ Squid proxy configured"

# Security hardening
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || true
systemctl restart ssh || true

dpkg-reconfigure -plow unattended-upgrades || true

systemctl enable fail2ban
systemctl start fail2ban

# Install Playmo SmartDNS API
echo "Installing Playmo SmartDNS API..."
apt-get install -y python3 python3-pip python3-venv git curl

# Create API directory
mkdir -p /opt/playmo-smartdns-api
cd /opt/playmo-smartdns-api

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install flask==3.0.0 flask-cors==4.0.0 firebase-admin==6.4.0 gunicorn==21.2.0 requests==2.31.0 python-dotenv==1.0.0

# Download API app.py from GitHub (raw content)
echo "Downloading API application..."
if ! curl -s -f https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/api/app.py -o /opt/playmo-smartdns-api/app.py; then
    echo "ERROR: Failed to download app.py from GitHub. Please SSH into the instance and manually copy the file."
    echo "Creating minimal placeholder to prevent service startup failure..."
    cat > /opt/playmo-smartdns-api/app.py <<'MINIMAL'
#!/usr/bin/env python3
from flask import Flask, jsonify
app = Flask(__name__)
@app.route('/health', methods=['GET'])
def health(): return jsonify({'status': 'error', 'message': 'app.py not downloaded. Please SSH and fix.'}), 503
if __name__ == '__main__': app.run(host='0.0.0.0', port=5000)
MINIMAL
fi

# Set Firebase credentials from environment variable
if [ -n "$FIREBASE_CREDENTIALS" ]; then
    echo "$FIREBASE_CREDENTIALS" > /opt/playmo-smartdns-api/firebase-credentials.json
    chmod 600 /opt/playmo-smartdns-api/firebase-credentials.json
fi

# Create systemd service
cat > /etc/systemd/system/playmo-smartdns-api.service <<EOFSERVICE
[Unit]
Description=Playmo SmartDNS Firebase API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/playmo-smartdns-api
Environment="PATH=/opt/playmo-smartdns-api/venv/bin"
Environment="FIREBASE_CREDENTIALS=${FIREBASE_CREDENTIALS}"
Environment="LAMBDA_WHITELIST_URL=${LAMBDA_WHITELIST_URL}"
Environment="SECURITY_GROUP_ID=${SECURITY_GROUP_ID}"
ExecStart=/opt/playmo-smartdns-api/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 30 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Enable and start API service
systemctl daemon-reload
systemctl enable playmo-smartdns-api
systemctl start playmo-smartdns-api

echo "Playmo SmartDNS API installed successfully!"