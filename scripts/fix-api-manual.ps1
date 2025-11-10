# Manual API Fix Script
# This provides commands to run via SSH if the API didn't start

$EC2_IP = "3.151.46.11"

Write-Host "Manual API Fix Instructions" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Gray
Write-Host ""

Write-Host "The API is not accessible. This usually means:" -ForegroundColor Yellow
Write-Host "1. Instance is still initializing (wait 3-5 minutes)" -ForegroundColor White
Write-Host "2. user_data script didn't run (instance wasn't recreated)" -ForegroundColor White
Write-Host "3. API service failed to start" -ForegroundColor White
Write-Host ""

Write-Host "SSH into the instance and run these commands:" -ForegroundColor Cyan
Write-Host "  ssh -i <your-key.pem> ubuntu@$EC2_IP" -ForegroundColor White
Write-Host ""

Write-Host "Then run these commands on the instance:" -ForegroundColor Yellow
Write-Host ""
Write-Host "# 1. Check if API service exists and its status" -ForegroundColor Gray
Write-Host "sudo systemctl status playmo-smartdns-api" -ForegroundColor White
Write-Host ""
Write-Host "# 2. Check if app.py exists and was downloaded correctly" -ForegroundColor Gray
Write-Host "ls -la /opt/playmo-smartdns-api/app.py" -ForegroundColor White
Write-Host "head -20 /opt/playmo-smartdns-api/app.py" -ForegroundColor White
Write-Host ""
Write-Host "# 3. If app.py is missing or is the placeholder, download it:" -ForegroundColor Gray
Write-Host "sudo curl -o /opt/playmo-smartdns-api/app.py https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/api/app.py" -ForegroundColor White
Write-Host ""
Write-Host "# 4. Check if Python dependencies are installed" -ForegroundColor Gray
Write-Host "cd /opt/playmo-smartdns-api && source venv/bin/activate && pip list | grep flask" -ForegroundColor White
Write-Host ""
Write-Host "# 5. If dependencies are missing, install them:" -ForegroundColor Gray
Write-Host "cd /opt/playmo-smartdns-api" -ForegroundColor White
Write-Host "source venv/bin/activate" -ForegroundColor White
Write-Host "pip install flask==3.0.0 flask-cors==4.0.0 firebase-admin==6.4.0 gunicorn==21.2.0 requests==2.31.0 python-dotenv==1.0.0" -ForegroundColor White
Write-Host ""
Write-Host "# 6. Check service logs for errors" -ForegroundColor Gray
Write-Host "sudo journalctl -u playmo-smartdns-api -n 100 --no-pager" -ForegroundColor White
Write-Host ""
Write-Host "# 7. Restart the API service" -ForegroundColor Gray
Write-Host "sudo systemctl restart playmo-smartdns-api" -ForegroundColor White
Write-Host "sudo systemctl status playmo-smartdns-api" -ForegroundColor White
Write-Host ""
Write-Host "# 8. Check if port 5000 is listening" -ForegroundColor Gray
Write-Host "sudo ss -tlnp | grep 5000" -ForegroundColor White
Write-Host ""
Write-Host "# 9. Test the API locally on the instance" -ForegroundColor Gray
Write-Host "curl http://localhost:5000/health" -ForegroundColor White
Write-Host ""
Write-Host "If the service still doesn't start, check:" -ForegroundColor Yellow
Write-Host "- Firebase credentials: sudo cat /opt/playmo-smartdns-api/firebase-credentials.json" -ForegroundColor White
Write-Host "- Environment variables: sudo systemctl show playmo-smartdns-api | grep Environment" -ForegroundColor White
Write-Host "- Full initialization log: sudo tail -200 /var/log/cloud-init-output.log" -ForegroundColor White
Write-Host ""

