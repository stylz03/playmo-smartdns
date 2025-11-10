# Complete Firebase Setup Checklist for Playmo SmartDNS

$npmPath = "C:\Users\tinas\AppData\Roaming\npm"
$env:Path += ";$npmPath"

Write-Host "Firebase Setup Checklist for Playmo SmartDNS" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Project: playmo-tech" -ForegroundColor Green
Write-Host ""

# Step 1: Firestore
Write-Host "Step 1: Enable Firestore Database" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Yellow
Write-Host "1. Go to: https://console.firebase.google.com/project/playmo-tech/firestore" -ForegroundColor Cyan
Write-Host "2. If you see 'Create database', click it" -ForegroundColor White
Write-Host "3. Choose 'Start in production mode'" -ForegroundColor White
Write-Host "4. Select location: us-central1 (or closest to your users)" -ForegroundColor White
Write-Host "5. Click 'Enable'" -ForegroundColor White
Write-Host ""

$firestoreDone = Read-Host "Is Firestore enabled? (y/n)"
if ($firestoreDone -eq "y" -or $firestoreDone -eq "Y") {
    Write-Host "✅ Firestore enabled" -ForegroundColor Green
} else {
    Write-Host "⚠️  Please enable Firestore first" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Service Account Key
Write-Host "Step 2: Generate Service Account Key" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Yellow
Write-Host "1. Go to: https://console.firebase.google.com/project/playmo-tech/settings/serviceaccounts/adminsdk" -ForegroundColor Cyan
Write-Host "2. Click 'Generate new private key'" -ForegroundColor White
Write-Host "3. Click 'Generate key' in the confirmation dialog" -ForegroundColor White
Write-Host "4. The JSON file will download automatically" -ForegroundColor White
Write-Host "5. Open the JSON file and copy ALL its contents" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  IMPORTANT: Save this key securely! You won't be able to see it again." -ForegroundColor Red
Write-Host ""

$keyGenerated = Read-Host "Have you generated and downloaded the service account key? (y/n)"
if ($keyGenerated -eq "y" -or $keyGenerated -eq "Y") {
    Write-Host "✅ Service account key ready" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next: Add to GitHub Secrets" -ForegroundColor Cyan
    Write-Host "1. Go to: https://github.com/stylz03/playmo-smartdns/settings/secrets/actions" -ForegroundColor White
    Write-Host "2. Click 'New repository secret'" -ForegroundColor White
    Write-Host "3. Name: FIREBASE_CREDENTIALS" -ForegroundColor White
    Write-Host "4. Value: Paste the ENTIRE JSON file contents" -ForegroundColor White
    Write-Host "5. Click 'Add secret'" -ForegroundColor White
} else {
    Write-Host "⚠️  Please generate the service account key first" -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Firestore Security Rules
Write-Host "Step 3: Set Firestore Security Rules" -ForegroundColor Yellow
Write-Host "-------------------------------------" -ForegroundColor Yellow
Write-Host "1. Go to: https://console.firebase.google.com/project/playmo-tech/firestore/rules" -ForegroundColor Cyan
Write-Host "2. Replace the rules with the ones from docs/FIREBASE_SETUP.md" -ForegroundColor White
Write-Host "3. Click 'Publish'" -ForegroundColor White
Write-Host ""

Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "After completing all steps, you can:" -ForegroundColor Cyan
Write-Host "1. Push code to trigger GitHub Actions deployment" -ForegroundColor White
Write-Host "2. Test API: curl http://EC2_IP:5000/health" -ForegroundColor White
Write-Host ""

