# Quick Firebase Login Script
# Adds Firebase CLI to PATH and runs login

$npmPath = "C:\Users\tinas\AppData\Roaming\npm"
$env:Path += ";$npmPath"

Write-Host "Firebase Login" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase is available
if (Test-Path "$npmPath\firebase.cmd") {
    Write-Host "Firebase CLI found" -ForegroundColor Green
    Write-Host ""
    Write-Host "Starting Firebase login..." -ForegroundColor Yellow
    Write-Host "This will open a browser for authentication." -ForegroundColor White
    Write-Host ""
    
    firebase login
} else {
    Write-Host "Firebase CLI not found. Installing..." -ForegroundColor Red
    npm install -g firebase-tools
    firebase login
}

Write-Host ""
Write-Host "After login, you can:" -ForegroundColor Cyan
Write-Host "1. Create a project: firebase projects:create PROJECT_ID" -ForegroundColor White
Write-Host "2. Or use the web console: https://console.firebase.google.com/" -ForegroundColor White
Write-Host "3. Run setup script: .\scripts\setup-firebase.ps1" -ForegroundColor White
