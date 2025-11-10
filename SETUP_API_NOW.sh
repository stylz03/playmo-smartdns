#!/bin/bash
# Complete API setup script - run this on the EC2 instance

set -e

echo "=== Setting up Playmo SmartDNS API ==="

# Step 1: Install dependencies
echo "Installing system packages..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv git curl

# Step 2: Create API directory
echo "Creating API directory..."
sudo mkdir -p /opt/playmo-smartdns-api
cd /opt/playmo-smartdns-api

# Step 3: Create virtual environment
echo "Creating virtual environment..."
sudo python3 -m venv venv
sudo chown -R ubuntu:ubuntu /opt/playmo-smartdns-api

# Step 4: Activate venv and install Python packages
echo "Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install flask==3.0.0 flask-cors==4.0.0 firebase-admin==6.4.0 gunicorn==21.2.0 requests==2.31.0 python-dotenv==1.0.0

# Step 5: Download app.py
echo "Downloading app.py..."
curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/api/app.py -o app.py

# Step 6: Check for Firebase credentials (will be set via systemd)
echo "Firebase credentials will be set via systemd service"

# Step 7: Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/playmo-smartdns-api.service > /dev/null <<'EOFSERVICE'
[Unit]
Description=Playmo SmartDNS Firebase API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/playmo-smartdns-api
Environment="PATH=/opt/playmo-smartdns-api/venv/bin"
Environment="FIREBASE_CREDENTIALS="
Environment="LAMBDA_WHITELIST_URL="
ExecStart=/opt/playmo-smartdns-api/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 30 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Step 8: Enable and start service
echo "Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable playmo-smartdns-api
sudo systemctl start playmo-smartdns-api

# Step 9: Check status
echo "Checking service status..."
sleep 2
sudo systemctl status playmo-smartdns-api --no-pager

echo ""
echo "=== Setup Complete ==="
echo "Test the API with: curl http://localhost:5000/health"

