#!/bin/bash
# Complete API setup - Run: sudo bash SETUP_API_DIRECT.sh

set -e

echo "=== Setting up Playmo SmartDNS API ==="

# 1. Create directory structure
mkdir -p /opt/playmo-smartdns-api
cd /opt/playmo-smartdns-api

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install Python dependencies
pip install --upgrade pip
pip install flask==3.0.0 flask-cors==4.0.0 firebase-admin==6.4.0 gunicorn==21.2.0 requests==2.31.0 python-dotenv==1.0.0

# 4. Download app.py
curl -s -f https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/api/app.py -o app.py
chmod +x app.py

# 5. Get security group ID
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
SECURITY_GROUP_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text --region us-east-2)

# 6. Create systemd service
cat > /tmp/playmo-api.service <<EOFSERVICE
[Unit]
Description=Playmo SmartDNS Firebase API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/playmo-smartdns-api
Environment="PATH=/opt/playmo-smartdns-api/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="FIREBASE_CREDENTIALS_FILE=/opt/playmo-smartdns-api/firebase-credentials.json"
Environment="LAMBDA_WHITELIST_URL="
Environment="SECURITY_GROUP_ID=${SECURITY_GROUP_ID}"
ExecStart=/opt/playmo-smartdns-api/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 30 --access-logfile - --error-logfile - app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

sudo mv /tmp/playmo-api.service /etc/systemd/system/playmo-smartdns-api.service

# 7. Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable playmo-smartdns-api
sudo systemctl start playmo-smartdns-api

# 8. Wait and check status
sleep 3
sudo systemctl status playmo-smartdns-api --no-pager -l | head -15

# 9. Test API
echo ""
echo "Testing API..."
curl http://localhost:5000/health

echo ""
echo "=== Setup Complete ==="

