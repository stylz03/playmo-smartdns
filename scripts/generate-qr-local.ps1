# Generate QR code for WireGuard config locally (PowerShell)
# Usage: .\generate-qr-local.ps1 <config-file>

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputName
)

# Check if config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Error: Config file not found: $ConfigFile" -ForegroundColor Red
    exit 1
}

# Determine output name
if (-not $OutputName) {
    $OutputName = [System.IO.Path]::GetFileNameWithoutExtension($ConfigFile)
}

# Check if Python is available
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command python3 -ErrorAction SilentlyContinue
}

if ($python) {
    Write-Host "Using Python to generate QR code..." -ForegroundColor Cyan
    & $python.Name "$PSScriptRoot\generate-qr-local.py" $ConfigFile $OutputName
    exit 0
}

# Fallback: Use online QR code generator API
Write-Host "Python not found. Using online QR code generator..." -ForegroundColor Yellow

# Read config content
$configContent = Get-Content $ConfigFile -Raw

# URL encode the content
$encodedContent = [System.Web.HttpUtility]::UrlEncode($configContent)

# Generate QR code using online service
$qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=$encodedContent"
$outputFile = "$OutputName.png"

try {
    Write-Host "Downloading QR code..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $qrUrl -OutFile $outputFile
    Write-Host "✅ QR code saved: $outputFile" -ForegroundColor Green
    Write-Host "`nShare $outputFile with your customer!" -ForegroundColor Cyan
} catch {
    Write-Host "Error generating QR code: $_" -ForegroundColor Red
    Write-Host "`nAlternative: Install Python and qrcode library:" -ForegroundColor Yellow
    Write-Host "  pip install qrcode[pil]" -ForegroundColor Gray
    Write-Host "  python generate-qr-local.py $ConfigFile" -ForegroundColor Gray
    exit 1
}

