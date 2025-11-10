# Initialize Firestore for Playmo SmartDNS
# This script sets up Firestore in the playmo-tech project

$npmPath = "C:\Users\tinas\AppData\Roaming\npm"
$env:Path += ";$npmPath"

Write-Host "Initializing Firestore for Playmo SmartDNS" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Set project
Write-Host "Setting Firebase project to: playmo-tech" -ForegroundColor Yellow
firebase use playmo-tech

Write-Host ""
Write-Host "Checking Firestore status..." -ForegroundColor Yellow

# Check if Firestore is already initialized
$firestoreExists = Test-Path "firestore.rules" -or Test-Path "firestore.indexes.json"

if ($firestoreExists) {
    Write-Host "Firestore appears to be already initialized." -ForegroundColor Green
    Write-Host ""
    Write-Host "To initialize Firestore in the Firebase Console:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://console.firebase.google.com/project/playmo-tech/firestore" -ForegroundColor White
    Write-Host "2. Click 'Create database' if not already created" -ForegroundColor White
    Write-Host "3. Choose 'Start in production mode'" -ForegroundColor White
    Write-Host "4. Select a location (us-central1 recommended)" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Initializing Firestore..." -ForegroundColor Yellow
    Write-Host "When prompted:" -ForegroundColor White
    Write-Host "  - Select 'Firestore'" -ForegroundColor Gray
    Write-Host "  - Choose 'Start in production mode' (we'll set rules later)" -ForegroundColor Gray
    Write-Host "  - Select location (us-central1 recommended)" -ForegroundColor Gray
    Write-Host ""
    
    $init = Read-Host "Run 'firebase init firestore' now? (y/n)"
    if ($init -eq "y" -or $init -eq "Y") {
        firebase init firestore
    } else {
        Write-Host ""
        Write-Host "You can initialize Firestore manually:" -ForegroundColor Yellow
        Write-Host "1. Go to: https://console.firebase.google.com/project/playmo-tech/firestore" -ForegroundColor Cyan
        Write-Host "2. Click 'Create database'" -ForegroundColor White
        Write-Host "3. Follow the wizard" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Generate service account key:" -ForegroundColor White
Write-Host "   https://console.firebase.google.com/project/playmo-tech/settings/serviceaccounts/adminsdk" -ForegroundColor Gray
Write-Host "2. Copy the JSON and add to GitHub Secrets as FIREBASE_CREDENTIALS" -ForegroundColor White
Write-Host "3. Set Firestore security rules (see docs/FIREBASE_SETUP.md)" -ForegroundColor White
Write-Host ""

