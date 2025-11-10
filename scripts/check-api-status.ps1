# Check API Status and Provide Diagnostic Steps
$EC2_IP = "3.151.46.11"

Write-Host "SmartDNS API Diagnostic Check" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Gray
Write-Host ""

Write-Host "Current Status: API not reachable at http://$EC2_IP:5000" -ForegroundColor Yellow
Write-Host ""

Write-Host "Possible Causes:" -ForegroundColor Yellow
Write-Host "1. Instance still initializing (user_data script running)" -ForegroundColor White
Write-Host "2. API service failed to start" -ForegroundColor White
Write-Host "3. API file download from GitHub failed" -ForegroundColor White
Write-Host "4. Firebase credentials not configured" -ForegroundColor White
Write-Host "5. Security group blocking connection (unlikely - set to 0.0.0.0/0)" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host ""

Write-Host "Option 1: Check GitHub Actions Logs" -ForegroundColor Yellow
Write-Host "1. Go to: https://github.com/stylz03/playmo-smartdns/actions" -ForegroundColor White
Write-Host "2. Open the latest workflow run" -ForegroundColor White
Write-Host "3. Check the 'Terraform Apply' step for any errors" -ForegroundColor White
Write-Host "4. Look for 'user_data' execution logs" -ForegroundColor White
Write-Host ""

Write-Host "Option 2: SSH into Instance and Check Manually" -ForegroundColor Yellow
Write-Host "If you have SSH access, run these commands:" -ForegroundColor White
Write-Host ""
Write-Host "  # Check if API service is running" -ForegroundColor Gray
Write-Host "  sudo systemctl status playmo-smartdns-api" -ForegroundColor White
Write-Host ""
Write-Host "  # Check service logs" -ForegroundColor Gray
Write-Host "  sudo journalctl -u playmo-smartdns-api -n 100 --no-pager" -ForegroundColor White
Write-Host ""
Write-Host "  # Check if app.py was downloaded" -ForegroundColor Gray
Write-Host "  ls -la /opt/playmo-smartdns-api/app.py" -ForegroundColor White
Write-Host "  head -20 /opt/playmo-smartdns-api/app.py" -ForegroundColor White
Write-Host ""
Write-Host "  # Check initialization logs" -ForegroundColor Gray
Write-Host "  sudo tail -100 /var/log/cloud-init-output.log" -ForegroundColor White
Write-Host ""
Write-Host "  # Check if port 5000 is listening" -ForegroundColor Gray
Write-Host "  sudo netstat -tlnp | grep 5000" -ForegroundColor White
Write-Host "  # OR" -ForegroundColor Gray
Write-Host "  sudo ss -tlnp | grep 5000" -ForegroundColor White
Write-Host ""

Write-Host "Option 3: Check AWS Console" -ForegroundColor Yellow
Write-Host "1. Go to: https://console.aws.amazon.com/ec2/" -ForegroundColor White
Write-Host "2. Navigate to: Instances -> playmo-smartdns-dns-only-ec2" -ForegroundColor White
Write-Host "3. Check 'Status checks' - should show '2/2 checks passed'" -ForegroundColor White
Write-Host "4. Check 'System log' or 'Instance logs' for initialization status" -ForegroundColor White
Write-Host ""

Write-Host "Option 4: Verify Security Group" -ForegroundColor Yellow
Write-Host "1. In EC2 Console, select the instance" -ForegroundColor White
Write-Host "2. Go to 'Security' tab" -ForegroundColor White
Write-Host "3. Click on the security group" -ForegroundColor White
Write-Host "4. Verify there's an inbound rule for:" -ForegroundColor White
Write-Host "   - Type: Custom TCP" -ForegroundColor Gray
Write-Host "   - Port: 5000" -ForegroundColor Gray
Write-Host "   - Source: 0.0.0.0/0 (or your IP)" -ForegroundColor Gray
Write-Host ""

Write-Host "Common Fixes:" -ForegroundColor Cyan
Write-Host ""
Write-Host "If app.py download failed:" -ForegroundColor Yellow
Write-Host "  sudo curl -o /opt/playmo-smartdns-api/app.py https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/api/app.py" -ForegroundColor White
Write-Host "  sudo systemctl restart playmo-smartdns-api" -ForegroundColor White
Write-Host ""
Write-Host "If service failed to start:" -ForegroundColor Yellow
Write-Host "  sudo systemctl start playmo-smartdns-api" -ForegroundColor White
Write-Host "  sudo systemctl enable playmo-smartdns-api" -ForegroundColor White
Write-Host ""
Write-Host "If Firebase credentials missing:" -ForegroundColor Yellow
Write-Host "  Check GitHub Secrets -> FIREBASE_CREDENTIALS is set" -ForegroundColor White
Write-Host "  Verify it was passed to the instance via user_data" -ForegroundColor White
Write-Host ""

Write-Host "Test Command (try again in a few minutes):" -ForegroundColor Cyan
Write-Host "  curl http://$EC2_IP:5000/health" -ForegroundColor White
Write-Host ""

