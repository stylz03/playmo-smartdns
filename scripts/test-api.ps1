# Test SmartDNS API Endpoints
$EC2_IP = "3.151.46.11"
$API_BASE = "http://${EC2_IP}:5000"

Write-Host "Testing SmartDNS API at $API_BASE" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Gray

# Test 1: Health Check
Write-Host "`n1. Testing /health endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$API_BASE/health" -Method GET -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ Health check successful!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor White
    Write-Host "Response:" -ForegroundColor White
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Health check failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPossible reasons:" -ForegroundColor Yellow
    Write-Host "- EC2 instance is still initializing (wait 2-3 minutes)" -ForegroundColor Gray
    Write-Host "- Security group doesn't allow your IP on port 5000" -ForegroundColor Gray
    Write-Host "- API service failed to start" -ForegroundColor Gray
    Write-Host "`nTo check the service status, SSH into the instance and run:" -ForegroundColor Cyan
    Write-Host "  sudo systemctl status playmo-smartdns-api" -ForegroundColor White
}

# Test 2: Stats endpoint (if health check works)
Write-Host "`n2. Testing /api/stats endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$API_BASE/api/stats" -Method GET -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ Stats endpoint successful!" -ForegroundColor Green
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Stats endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Clients endpoint
Write-Host "`n3. Testing /api/clients endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$API_BASE/api/clients" -Method GET -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ Clients endpoint successful!" -ForegroundColor Green
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Clients endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + ("=" * 50) -ForegroundColor Gray
Write-Host "API Base URL: $API_BASE" -ForegroundColor Cyan

