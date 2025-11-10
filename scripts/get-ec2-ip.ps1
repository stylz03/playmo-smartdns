# Get EC2 Public IP Address
# This script retrieves the Elastic IP of the SmartDNS EC2 instance

Write-Host "Fetching EC2 Public IP address..." -ForegroundColor Cyan

# Try to get from AWS CLI if available
try {
    $ip = aws ec2 describe-instances `
        --filters "Name=tag:Name,Values=playmo-smartdns-dns-only-ec2" "Name=instance-state-name,Values=running" `
        --query 'Reservations[0].Instances[0].PublicIpAddress' `
        --output text `
        --region us-east-2 2>$null
    
    if ($ip -and $ip -ne "None" -and $ip -match '^\d+\.\d+\.\d+\.\d+$') {
        Write-Host "`n✅ EC2 Public IP: $ip" -ForegroundColor Green
        Write-Host "`nAPI Health Check URL:" -ForegroundColor Yellow
        Write-Host "  http://$ip:5000/health" -ForegroundColor White
        Write-Host "`nAPI Base URL:" -ForegroundColor Yellow
        Write-Host "  http://$ip:5000" -ForegroundColor White
        Write-Host "`nTo test the health endpoint, run:" -ForegroundColor Cyan
        Write-Host "  curl http://$ip:5000/health" -ForegroundColor White
        return
    }
} catch {
    Write-Host "AWS CLI not available or not configured" -ForegroundColor Yellow
}

Write-Host "`n⚠️  Could not automatically retrieve IP address." -ForegroundColor Yellow
Write-Host "`nTo get the IP address, you can:" -ForegroundColor Cyan
Write-Host "1. Check GitHub Actions workflow run output" -ForegroundColor White
Write-Host "2. Check AWS Console -> EC2 -> Instances" -ForegroundColor White
Write-Host "3. Check Terraform outputs (if running locally)" -ForegroundColor White
Write-Host "`nThe IP should be displayed in the 'Capture Terraform Outputs' step" -ForegroundColor Gray


