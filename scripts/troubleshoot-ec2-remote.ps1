# Troubleshoot SmartDNS EC2 instance remotely
# Usage: .\scripts\troubleshoot-ec2-remote.ps1

$REGION = "us-east-2"
$PROJECT_NAME = "playmo-smartdns-dns-only"

Write-Host "`n=== Remote EC2 Troubleshooting ===" -ForegroundColor Cyan
Write-Host "Region: $REGION`n" -ForegroundColor White

# Check if AWS CLI is configured
Write-Host "1. Checking AWS CLI configuration..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
    Write-Host "   ✅ AWS CLI configured" -ForegroundColor Green
    Write-Host "   Account: $($identity.Account)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ AWS CLI not configured" -ForegroundColor Red
    Write-Host "   Run: aws configure" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Find the EC2 instance
Write-Host "2. Finding EC2 instance..." -ForegroundColor Yellow
$instanceJson = aws ec2 describe-instances `
    --region $REGION `
    --filters "Name=tag:Name,Values=${PROJECT_NAME}-ec2" "Name=instance-state-name,Values=running" `
    --query 'Reservations[0].Instances[0]' `
    --output json 2>&1

if ($LASTEXITCODE -ne 0 -or $instanceJson -eq "null" -or [string]::IsNullOrWhiteSpace($instanceJson)) {
    Write-Host "   ❌ Instance not found or not running" -ForegroundColor Red
    exit 1
}

$instance = $instanceJson | ConvertFrom-Json
$instanceId = $instance.InstanceId
$publicIp = $instance.PublicIpAddress
$state = $instance.State.Name

Write-Host "   ✅ Instance found:" -ForegroundColor Green
Write-Host "   Instance ID: $instanceId" -ForegroundColor White
Write-Host "   Public IP: $publicIp" -ForegroundColor White
Write-Host "   State: $state" -ForegroundColor White

Write-Host ""

# Check security group
Write-Host "3. Checking security group rules..." -ForegroundColor Yellow
$sgId = $instance.SecurityGroups[0].GroupId
$sgRules = aws ec2 describe-security-groups `
    --region $REGION `
    --group-ids $sgId `
    --query 'SecurityGroups[0].IpPermissions' `
    --output json | ConvertFrom-Json

Write-Host "   Security Group: $sgId" -ForegroundColor White

$dnsUdp = $sgRules | Where-Object { $_.FromPort -eq 53 -and $_.IpProtocol -eq "udp" }
$dnsTcp = $sgRules | Where-Object { $_.FromPort -eq 53 -and $_.IpProtocol -eq "tcp" }
$apiPort = $sgRules | Where-Object { $_.FromPort -eq 5000 }
$proxyPort = $sgRules | Where-Object { $_.FromPort -eq 3128 }

if ($dnsUdp) {
    Write-Host "   ✅ DNS UDP (53) allowed" -ForegroundColor Green
} else {
    Write-Host "   ❌ DNS UDP (53) NOT allowed" -ForegroundColor Red
}

if ($dnsTcp) {
    Write-Host "   ✅ DNS TCP (53) allowed" -ForegroundColor Green
} else {
    Write-Host "   ❌ DNS TCP (53) NOT allowed" -ForegroundColor Red
}

if ($apiPort) {
    Write-Host "   ✅ API HTTP (5000) allowed" -ForegroundColor Green
} else {
    Write-Host "   ❌ API HTTP (5000) NOT allowed" -ForegroundColor Red
}

if ($proxyPort) {
    Write-Host "   ✅ Proxy HTTP (3128) allowed" -ForegroundColor Green
} else {
    Write-Host "   ❌ Proxy HTTP (3128) NOT allowed" -ForegroundColor Red
}

Write-Host ""

# Check if we can SSH (to run commands)
Write-Host "4. Checking SSH access..." -ForegroundColor Yellow
Write-Host "   To check services, you need to SSH into the instance:" -ForegroundColor White
Write-Host "   ssh -i your-key.pem ubuntu@$publicIp" -ForegroundColor Gray
Write-Host ""
Write-Host "   Then run these commands:" -ForegroundColor Yellow
Write-Host "   sudo systemctl status bind9" -ForegroundColor Gray
Write-Host "   sudo systemctl status playmo-smartdns-api" -ForegroundColor Gray
Write-Host "   sudo systemctl status squid" -ForegroundColor Gray
Write-Host "   sudo ss -tulnp | grep -E '53|5000|3128'" -ForegroundColor Gray
Write-Host "   curl http://localhost:5000/health" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Troubleshooting Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. SSH into the instance and check service status" -ForegroundColor White
Write-Host "2. Check BIND9 logs: sudo journalctl -u bind9 -n 50" -ForegroundColor White
Write-Host "3. Check API logs: sudo journalctl -u playmo-smartdns-api -n 50" -ForegroundColor White
Write-Host "4. Verify security group allows your IP for port 5000" -ForegroundColor White

