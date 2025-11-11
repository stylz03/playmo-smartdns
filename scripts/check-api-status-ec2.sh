#!/bin/bash
# Check API status on EC2 instance
# Run this via SSH: bash check-api-status-ec2.sh

echo "=== Checking SmartDNS API Status ==="
echo ""

# Check if service is running
echo "1. Checking systemd service status..."
sudo systemctl status playmo-smartdns-api --no-pager -l | head -20

echo ""
echo "2. Checking if port 5000 is listening..."
sudo ss -tulnp | grep 5000 || echo "Port 5000 not listening"

echo ""
echo "3. Checking API logs (last 20 lines)..."
sudo journalctl -u playmo-smartdns-api -n 20 --no-pager

echo ""
echo "4. Testing API locally..."
curl -s http://localhost:5000/health || echo "API not responding locally"

echo ""
echo "5. Checking if app.py exists..."
ls -la /opt/playmo-smartdns-api/app.py || echo "app.py not found"

echo ""
echo "=== Check Complete ==="

