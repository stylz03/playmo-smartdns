# Troubleshoot SmartDNS API Connection
$EC2_IP = "3.151.46.11"

Write-Host "SmartDNS API Troubleshooting Guide" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Gray
Write-Host "EC2 IP Address: $EC2_IP" -ForegroundColor White
Write-Host "API URL: http://$EC2_IP:5000" -ForegroundColor White
Write-Host ""

Write-Host "Step 1: Check if instance is still initializing" -ForegroundColor Yellow
Write-Host "The user_data script can take 2-5 minutes to complete." -ForegroundColor Gray
Write-Host "It installs:" -ForegroundColor Gray
Write-Host "  - BIND9 DNS server" -ForegroundColor Gray
Write-Host "  - Python and dependencies" -ForegroundColor Gray
Write-Host "  - Firebase API service" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 2: Test basic connectivity" -ForegroundColor Yellow
Write-Host "Testing if port 5000 is reachable..." -ForegroundColor Gray
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect($EC2_IP, 5000, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
    if ($wait) {
        $tcpClient.EndConnect($connect)
        Write-Host "✅ Port 5000 is reachable!" -ForegroundColor Green
        $tcpClient.Close()
    } else {
        Write-Host "❌ Port 5000 is not reachable (connection timeout)" -ForegroundColor Red
        Write-Host "   The instance may still be initializing." -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Port 5000 is not reachable: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 3: If you have SSH access, check the service status" -ForegroundColor Yellow
Write-Host "SSH into the instance and run:" -ForegroundColor Cyan
Write-Host "  ssh -i <your-key.pem> ubuntu@$EC2_IP" -ForegroundColor White
Write-Host ""
Write-Host "Then check the API service:" -ForegroundColor Cyan
Write-Host "  sudo systemctl status playmo-smartdns-api" -ForegroundColor White
Write-Host "  sudo journalctl -u playmo-smartdns-api -n 50" -ForegroundColor White
Write-Host ""

Write-Host "Step 4: Check if the API file was downloaded" -ForegroundColor Yellow
Write-Host "  ls -la /opt/playmo-smartdns-api/app.py" -ForegroundColor White
Write-Host "  cat /opt/playmo-smartdns-api/app.py | head -20" -ForegroundColor White
Write-Host ""

Write-Host "Step 5: Manual API test (wait 2-3 minutes, then try again)" -ForegroundColor Yellow
Write-Host "  curl http://$EC2_IP:5000/health" -ForegroundColor White
Write-Host ""

Write-Host "Common Issues:" -ForegroundColor Yellow
Write-Host "1. Instance still initializing - Wait 3-5 minutes" -ForegroundColor Gray
Write-Host "2. API download failed - Check /var/log/cloud-init-output.log" -ForegroundColor Gray
Write-Host "3. Service failed to start - Check systemd logs" -ForegroundColor Gray
Write-Host "4. Firebase credentials missing - Check environment variables" -ForegroundColor Gray

