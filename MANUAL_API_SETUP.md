# Manual API Setup Commands

Since the service doesn't exist, we need to set it up manually. Run these commands:

## Step 1: Check if the API directory exists
```bash
ls -la /opt/playmo-smartdns-api/
```

## Step 2: If directory doesn't exist, create it and set up Python
```bash
sudo mkdir -p /opt/playmo-smartdns-api
cd /opt/playmo-smartdns-api
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv git curl
```

## Step 3: Create virtual environment
```bash
cd /opt/playmo-smartdns-api
sudo python3 -m venv venv
source venv/bin/activate
```

## Step 4: Install Python dependencies
```bash
pip install --upgrade pip
pip install flask==3.0.0 flask-cors==4.0.0 firebase-admin==6.4.0 gunicorn==21.2.0 requests==2.31.0 python-dotenv==1.0.0
```

## Step 5: Download app.py
```bash
sudo curl -o /opt/playmo-smartdns-api/app.py https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/api/app.py
```

## Step 6: Set Firebase credentials (if available)
Check if they exist in environment:
```bash
echo $FIREBASE_CREDENTIALS | head -c 50
```

If they exist, save them:
```bash
sudo bash -c 'echo "$FIREBASE_CREDENTIALS" > /opt/playmo-smartdns-api/firebase-credentials.json'
sudo chmod 600 /opt/playmo-smartdns-api/firebase-credentials.json
```

## Step 7: Get Lambda URL
```bash
echo $LAMBDA_WHITELIST_URL
```

## Step 8: Create systemd service
```bash
sudo tee /etc/systemd/system/playmo-smartdns-api.service > /dev/null <<'EOFSERVICE'
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
```

## Step 9: Enable and start service
```bash
sudo systemctl daemon-reload
sudo systemctl enable playmo-smartdns-api
sudo systemctl start playmo-smartdns-api
sudo systemctl status playmo-smartdns-api
```

