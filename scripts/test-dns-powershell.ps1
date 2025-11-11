# Test DNS resolution with SmartDNS server
# Usage: .\scripts\test-dns-powershell.ps1

$DNS_SERVER = "3.151.46.11"

Write-Host "`n=== Testing SmartDNS Server ===" -ForegroundColor Cyan
Write-Host "DNS Server: $DNS_SERVER`n" -ForegroundColor White

# Test Netflix
Write-Host "Testing Netflix DNS resolution..." -ForegroundColor Yellow
try {
    $result = Resolve-DnsName -Name netflix.com -Server $DNS_SERVER -Type A -ErrorAction Stop
    Write-Host "✅ Netflix IPs:" -ForegroundColor Green
    $result | Where-Object { $_.Type -eq 'A' } | ForEach-Object {
        Write-Host "  - $($_.IPAddress)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Failed to resolve netflix.com: $_" -ForegroundColor Red
}

Write-Host ""

# Test Disney+
Write-Host "Testing Disney+ DNS resolution..." -ForegroundColor Yellow
try {
    $result = Resolve-DnsName -Name disneyplus.com -Server $DNS_SERVER -Type A -ErrorAction Stop
    Write-Host "✅ Disney+ IPs:" -ForegroundColor Green
    $result | Where-Object { $_.Type -eq 'A' } | ForEach-Object {
        Write-Host "  - $($_.IPAddress)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Failed to resolve disneyplus.com: $_" -ForegroundColor Red
}

Write-Host ""

# Test Hulu
Write-Host "Testing Hulu DNS resolution..." -ForegroundColor Yellow
try {
    $result = Resolve-DnsName -Name hulu.com -Server $DNS_SERVER -Type A -ErrorAction Stop
    Write-Host "✅ Hulu IPs:" -ForegroundColor Green
    $result | Where-Object { $_.Type -eq 'A' } | ForEach-Object {
        Write-Host "  - $($_.IPAddress)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Failed to resolve hulu.com: $_" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan

