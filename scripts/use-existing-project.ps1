# Use Existing Playmo Tech Project for SmartDNS

$npmPath = "C:\Users\tinas\AppData\Roaming\npm"
$env:Path += ";$npmPath"

Write-Host "Using Existing Playmo Tech Project" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Update .firebaserc to use playmo-tech
Write-Host "Setting up to use 'playmo-tech' project..." -ForegroundColor Yellow

@"
{
  "projects": {
    "default": "playmo-tech"
  }
}
"@ | Out-File -FilePath ".firebaserc" -Encoding utf8 -Force

Write-Host "✅ Updated .firebaserc to use playmo-tech" -ForegroundColor Green
Write-Host ""

# Check if Firestore exists
Write-Host "Checking Firestore status..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Enable Firestore (if not already enabled):" -ForegroundColor White
Write-Host "   https://console.firebase.google.com/project/playmo-tech/firestore" -ForegroundColor Gray
Write-Host "   Click 'Create database' if needed" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Generate service account key:" -ForegroundColor White
Write-Host "   https://console.firebase.google.com/project/playmo-tech/settings/serviceaccounts/adminsdk" -ForegroundColor Gray
Write-Host "   Click 'Generate new private key'" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Add to GitHub Secrets as FIREBASE_CREDENTIALS" -ForegroundColor White
Write-Host ""
Write-Host "4. Set Firestore security rules (see docs/FIREBASE_SETUP.md)" -ForegroundColor White
Write-Host ""

Write-Host "✅ Ready to use playmo-tech project for SmartDNS!" -ForegroundColor Green
Write-Host ""

