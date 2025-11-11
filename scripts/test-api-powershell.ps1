# Test SmartDNS API endpoints
# Usage: .\scripts\test-api-powershell.ps1

$API_BASE = "http://3.151.46.11:5000"

Write-Host "`n=== Testing SmartDNS API ===" -ForegroundColor Cyan
Write-Host "API Base URL: $API_BASE`n" -ForegroundColor White

# Test Health Endpoint
Write-Host "Testing /health endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$API_BASE/health" -Method Get -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Health Check:" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor White
    Write-Host "  Response: $($response.Content)" -ForegroundColor White
} catch {
    Write-Host "❌ Health check failed: $_" -ForegroundColor Red
    Write-Host "  This might mean:" -ForegroundColor Yellow
    Write-Host "    - API service is not running on EC2" -ForegroundColor Gray
    Write-Host "    - Security group doesn't allow port 5000" -ForegroundColor Gray
    Write-Host "    - Instance is still initializing" -ForegroundColor Gray
}

Write-Host ""

# Test Stats Endpoint
Write-Host "Testing /api/stats endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$API_BASE/api/stats" -Method Get -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Stats:" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor White
    $stats = $response.Content | ConvertFrom-Json
    Write-Host "  Response:" -ForegroundColor White
    $stats | ConvertTo-Json -Depth 3 | Write-Host
} catch {
    Write-Host "❌ Stats endpoint failed: $_" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan

