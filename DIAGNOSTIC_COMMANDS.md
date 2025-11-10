# Diagnostic Commands for EC2 Instance

Run these commands in order to diagnose the API issue:

## 1. Check API Service Status
```bash
sudo systemctl status playmo-smartdns-api
```

## 2. Check Service Logs (if service exists)
```bash
sudo journalctl -u playmo-smartdns-api -n 100 --no-pager
```

## 3. Check if app.py exists and was downloaded correctly
```bash
ls -la /opt/playmo-smartdns-api/app.py
head -20 /opt/playmo-smartdns-api/app.py
```

## 4. Check if port 5000 is listening
```bash
sudo ss -tlnp | grep 5000
```

## 5. Check Python dependencies
```bash
cd /opt/playmo-smartdns-api
source venv/bin/activate
pip list | grep flask
```

## 6. Test API locally on the instance
```bash
curl http://localhost:5000/health
```

## 7. Check initialization logs
```bash
sudo tail -100 /var/log/cloud-init-output.log
```

## 8. Check Firebase credentials
```bash
sudo cat /opt/playmo-smartdns-api/firebase-credentials.json | head -5
```

## 9. Check environment variables
```bash
sudo systemctl show playmo-smartdns-api | grep Environment
```

## Quick Fixes

### If app.py is missing or is the placeholder:
```bash
sudo curl -o /opt/playmo-smartdns-api/app.py https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/api/app.py
sudo systemctl restart playmo-smartdns-api
```

### If dependencies are missing:
```bash
cd /opt/playmo-smartdns-api
source venv/bin/activate
pip install flask==3.0.0 flask-cors==4.0.0 firebase-admin==6.4.0 gunicorn==21.2.0 requests==2.31.0 python-dotenv==1.0.0
sudo systemctl restart playmo-smartdns-api
```

### If service doesn't exist, check if directory exists:
```bash
ls -la /opt/playmo-smartdns-api/
```

