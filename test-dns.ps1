# DNS Test Script for SmartDNS (PowerShell)
# This script tests DNS resolution against your SmartDNS EC2 instance

Write-Host "🔍 SmartDNS Testing Script" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host ""

# Get EC2 public IP from Terraform
$EC2_IP = $null
if (Test-Path "terraform\terraform.tfstate") {
    Push-Location terraform
    $terraformOutput = terraform output -raw ec2_public_ip 2>&1 | Out-String
    Pop-Location
    
    # Extract IP address using regex
    if ($terraformOutput -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
        $EC2_IP = $matches[1]
    }
}

if (-not $EC2_IP -or $EC2_IP -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
    Write-Host "⚠️  Terraform state not found or invalid IP. Please provide EC2 public IP:" -ForegroundColor Yellow
    $EC2_IP = Read-Host "EC2 Public IP"
}

if (-not $EC2_IP -or $EC2_IP -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
    Write-Host "❌ Invalid EC2 IP address: $EC2_IP" -ForegroundColor Red
    exit 1
}

Write-Host "📍 Testing against EC2 instance: $EC2_IP" -ForegroundColor Green
Write-Host ""

# Test domains
$testDomains = @(
    "netflix.com",
    "disneyplus.com",
    "hulu.com",
    "hbomax.com",
    "peacocktv.com",
    "youtube.com"  # This should NOT be forwarded
)

Write-Host "Testing streaming domains (should be forwarded to 8.8.8.8/1.1.1.1):" -ForegroundColor Cyan
Write-Host "-------------------------------------------------------------------" -ForegroundColor Cyan

foreach ($domain in $testDomains) {
    Write-Host -NoNewline "Testing $domain... "
    
    try {
        # Use Resolve-DnsName with custom DNS server
        $result = Resolve-DnsName -Name $domain -Server $EC2_IP -Type A -ErrorAction SilentlyContinue
        
        if ($result -and $result.IPAddress) {
            $ip = $result.IPAddress | Select-Object -First 1
            Write-Host "✅ OK - Resolved to $ip" -ForegroundColor Green
        } else {
            Write-Host "❌ FAILED - No IP address returned" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Testing non-streaming domain (should use normal DNS):" -ForegroundColor Cyan
Write-Host "-----------------------------------------------------" -ForegroundColor Cyan
Write-Host -NoNewline "Testing google.com... "

try {
    $result = Resolve-DnsName -Name "google.com" -Server $EC2_IP -Type A -ErrorAction SilentlyContinue
    if ($result -and $result.IPAddress) {
        $ip = $result.IPAddress | Select-Object -First 1
        Write-Host "✅ OK - Resolved to $ip" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================" -ForegroundColor Cyan
Write-Host "✅ DNS Testing Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 To use this DNS server:" -ForegroundColor Yellow
Write-Host "   Set your device DNS to: $EC2_IP" -ForegroundColor Yellow
Write-Host ""

