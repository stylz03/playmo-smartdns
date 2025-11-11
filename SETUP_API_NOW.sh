#!/bin/bash
# Complete API setup script - Run this on EC2: sudo bash SETUP_API_NOW.sh

set -e

echo "=== Setting up Playmo SmartDNS API ==="

# 1. Create directory structure
echo "1. Creating directory structure..."
mkdir -p /opt/playmo-smartdns-api
cd /opt/playmo-smartdns-api

# 2. Create virtual environment
echo "2. Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# 3. Install Python dependencies
echo "3. Installing Python dependencies..."
pip install --upgrade pip
pip install flask==3.0.0 flask-cors==4.0.0 firebase-admin==6.4.0 gunicorn==21.2.0 requests==2.31.0 python-dotenv==1.0.0

# 4. Download app.py
echo "4. Downloading app.py..."
if ! curl -s -f https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/api/app.py -o app.py; then
    echo "ERROR: Failed to download app.py"
    exit 1
fi
chmod +x app.py

# 5. Get environment variables from systemd (if they exist) or set defaults
echo "5. Setting up environment variables..."
# Get SECURITY_GROUP_ID from instance metadata or user_data
SECURITY_GROUP_ID=$(curl -s http://169.254.169.254/latest/meta-data/security-groups 2>/dev/null | head -1 || echo "")
if [ -z "$SECURITY_GROUP_ID" ]; then
    # Try to get from AWS CLI
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    SECURITY_GROUP_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text --region us-east-2 2>/dev/null || echo "")
fi

# Get Lambda URL from existing systemd service or set empty
LAMBDA_WHITELIST_URL=$(systemctl show playmo-smartdns-api.service 2>/dev/null | grep LAMBDA_WHITELIST_URL | cut -d= -f2 || echo "")

# Check if Firebase credentials exist
if [ -f /opt/playmo-smartdns-api/firebase-credentials.json ]; then
    echo "   Firebase credentials file found"
else
    echo "   ⚠️  Firebase credentials not found - API will work but Firebase features won't"
fi

# 6. Create systemd service
echo "6. Creating systemd service..."
cat > /etc/systemd/system/playmo-smartdns-api.service <<EOFSERVICE
[Unit]
Description=Playmo SmartDNS Firebase API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/playmo-smartdns-api
Environment="PATH=/opt/playmo-smartdns-api/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="FIREBASE_CREDENTIALS_FILE=/opt/playmo-smartdns-api/firebase-credentials.json"
Environment="LAMBDA_WHITELIST_URL=${LAMBDA_WHITELIST_URL}"
Environment="SECURITY_GROUP_ID=${SECURITY_GROUP_ID}"
ExecStart=/opt/playmo-smartdns-api/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 30 --access-logfile - --error-logfile - app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

# 7. Enable and start service
echo "7. Enabling and starting service..."
systemctl daemon-reload
systemctl enable playmo-smartdns-api
systemctl start playmo-smartdns-api

# 8. Wait a moment and check status
sleep 3
echo ""
echo "8. Checking service status..."
systemctl status playmo-smartdns-api --no-pager -l | head -15

# 9. Check if it's listening
echo ""
echo "9. Checking if API is listening..."
if ss -tulnp | grep -q ":5000"; then
    echo "   ✅ API is listening on port 5000"
    ss -tulnp | grep 5000
else
    echo "   ❌ API is not listening on port 5000"
    echo "   Check logs: sudo journalctl -u playmo-smartdns-api -n 50"
fi

# 10. Test API
echo ""
echo "10. Testing API..."
if curl -s http://localhost:5000/health > /dev/null; then
    echo "   ✅ API responds!"
    curl -s http://localhost:5000/health
else
    echo "   ❌ API does not respond"
    echo "   Check logs: sudo journalctl -u playmo-smartdns-api -n 50"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Test from your local machine:"
echo "  curl http://3.151.46.11:5000/health"
