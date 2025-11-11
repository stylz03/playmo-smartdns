#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get upgrade -y
apt-get install -y bind9 bind9utils bind9-dnsutils unattended-upgrades fail2ban build-essential libev-dev libpcre3-dev

# Bind9 global options (optimized for US-based SmartDNS)
cat > /etc/bind/named.conf.options <<'EOF'
${NAMED_CONF_OPTIONS}
EOF

# Create zones directory for static A records
mkdir -p /etc/bind/zones

# Zone files will be created by a separate script downloaded from GitHub
# This keeps user_data under 16KB limit
echo "Zone files will be created by setup script..."

# Download and run zone file setup script for sniproxy
echo "Downloading zone file setup script..."
if [ -n "${GITHUB_TOKEN}" ]; then
    curl -s -f --max-time 30 --retry 3 --retry-delay 2 -H "Authorization: token ${GITHUB_TOKEN}" https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/create-zone-files-sniproxy.sh -o /tmp/create-zones.sh || echo "Warning: Could not download zone setup script"
else
    curl -s -f --max-time 30 --retry 3 --retry-delay 2 https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/create-zone-files-sniproxy.sh -o /tmp/create-zones.sh || echo "Warning: Could not download zone setup script (private repo - token may be needed)"
fi
if [ -f /tmp/create-zones.sh ]; then
    chmod +x /tmp/create-zones.sh
    # Run zone file creation with EC2 IP (from Terraform variable)
    EC2_IP_VAL="$${EC2_PUBLIC_IP:-3.151.46.11}"
    bash /tmp/create-zones.sh "$$EC2_IP_VAL" || echo "Warning: Zone setup script failed"
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

# Install and configure sniproxy for SNI-based HTTPS forwarding
echo "Installing sniproxy..."
# Install sniproxy from source (not in default repos)
cd /tmp
git clone https://github.com/dlundquist/sniproxy.git || echo "sniproxy repo already exists"
cd sniproxy
if [ ! -f /usr/local/sbin/sniproxy ]; then
    ./autogen.sh
    ./configure
    make
    make install
fi

# Create sniproxy user if it doesn't exist
id -u sniproxy >/dev/null 2>&1 || useradd -r -s /bin/false sniproxy

# Create sniproxy directory
mkdir -p /etc/sniproxy

# Download sync script for sniproxy config (with timeout and retry)
echo "Downloading sniproxy config sync script..."
if [ -n "${GITHUB_TOKEN}" ]; then
    curl -s -f --max-time 30 --retry 3 --retry-delay 2 -H "Authorization: token ${GITHUB_TOKEN}" https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/sync-sniproxy-config.sh -o /usr/local/bin/sync-sniproxy-config.sh || echo "Warning: Could not download sync script"
else
    curl -s -f --max-time 30 --retry 3 --retry-delay 2 https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/sync-sniproxy-config.sh -o /usr/local/bin/sync-sniproxy-config.sh || echo "Warning: Could not download sync script (private repo - token may be needed)"
fi
if [ -f /usr/local/bin/sync-sniproxy-config.sh ]; then
    chmod +x /usr/local/bin/sync-sniproxy-config.sh
    # Initial sync from services.json
    EC2_IP_VAL="$${EC2_PUBLIC_IP:-3.151.46.11}"
    if [ -n "${GITHUB_TOKEN}" ]; then
        curl -s -f --max-time 30 --retry 3 --retry-delay 2 -H "Authorization: token ${GITHUB_TOKEN}" https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json -o /tmp/services.json
    else
        curl -s -f --max-time 30 --retry 3 --retry-delay 2 https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json -o /tmp/services.json || echo "Warning: Could not download services.json (private repo - token may be needed)"
    fi
    if [ -f /tmp/services.json ]; then
        EC2_IP="$$EC2_IP_VAL" /usr/local/bin/sync-sniproxy-config.sh /tmp/services.json /etc/sniproxy/sniproxy.conf || echo "Warning: Initial sync failed"
    fi
fi

# Set capabilities on sniproxy binary to allow binding to privileged ports
# This allows sniproxy to bind to ports 80/443 without running as root
setcap 'cap_net_bind_service=+ep' /usr/local/sbin/sniproxy 2>/dev/null || echo "Warning: Could not set capabilities, will run as root"

# Create systemd service for sniproxy
# Use Type=simple with -f flag (foreground mode) - this is the working configuration
cat > /etc/systemd/system/sniproxy.service <<'SNIPROXY_SERVICE'
[Unit]
Description=SNI Proxy for SmartDNS
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SNIPROXY_SERVICE

# Enable and start sniproxy
systemctl daemon-reload
systemctl enable sniproxy
systemctl start sniproxy || echo "Warning: sniproxy start failed, will retry after config sync"

echo "✅ sniproxy installed and configured"

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
if [ -n "${GITHUB_TOKEN}" ]; then
    DOWNLOAD_CMD="curl -s -f --max-time 30 --retry 3 --retry-delay 2 -H 'Authorization: token ${GITHUB_TOKEN}'"
else
    DOWNLOAD_CMD="curl -s -f --max-time 30 --retry 3 --retry-delay 2"
fi

if ! $DOWNLOAD_CMD https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/api/app.py -o /opt/playmo-smartdns-api/app.py; then
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