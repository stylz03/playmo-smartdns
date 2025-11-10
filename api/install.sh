#!/bin/bash
# Installation script for Playmo SmartDNS API
set -euo pipefail

API_DIR="/opt/playmo-smartdns-api"
SERVICE_USER="playmo-api"

echo "Installing Playmo SmartDNS API..."

# Create service user
if ! id "$SERVICE_USER" &>/dev/null; then
    useradd -r -s /bin/false "$SERVICE_USER"
fi

# Create API directory
mkdir -p "$API_DIR"
cd "$API_DIR"

# Install Python and pip if not already installed
apt-get update -y
apt-get install -y python3 python3-pip python3-venv

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Copy application files
cp app.py "$API_DIR/"
chmod +x "$API_DIR/app.py"

# Create systemd service
cat > /etc/systemd/system/playmo-smartdns-api.service <<EOF
[Unit]
Description=Playmo SmartDNS Firebase API
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$API_DIR
Environment="PATH=$API_DIR/venv/bin"
ExecStart=$API_DIR/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 30 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
chown -R "$SERVICE_USER:$SERVICE_USER" "$API_DIR"
chmod +x service.sh

# Enable and start service
systemctl daemon-reload
systemctl enable playmo-smartdns-api
systemctl start playmo-smartdns-api

echo "Playmo SmartDNS API installed and started successfully!"

