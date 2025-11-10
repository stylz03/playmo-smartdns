#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get upgrade -y
apt-get install -y bind9 bind9utils bind9-dnsutils unattended-upgrades fail2ban

# Bind9 global options
cat > /etc/bind/named.conf.options <<'EOF'
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

# Inject selective forward zones
cat > /etc/bind/named.conf.local <<'EOF'
${NAMED_CONF_LOCAL}
EOF

systemctl enable bind9
systemctl restart bind9

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