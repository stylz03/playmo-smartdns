# Playmo SmartDNS Firebase Setup Script
# This script helps you create and configure a Firebase project

Write-Host "🔥 Playmo SmartDNS Firebase Setup" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
try {
    $firebaseVersion = firebase --version 2>&1
    Write-Host "✅ Firebase CLI installed: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI not found. Installing..." -ForegroundColor Red
    npm install -g firebase-tools
}

Write-Host ""
Write-Host "Step 1: Login to Firebase" -ForegroundColor Yellow
Write-Host "You'll need to authenticate with your Google account." -ForegroundColor White
$login = Read-Host "Do you want to login to Firebase now? (y/n)"

if ($login -eq "y" -or $login -eq "Y") {
    Write-Host "Opening Firebase login in browser..." -ForegroundColor Cyan
    firebase login --no-localhost
} else {
    Write-Host "Skipping login. Run 'firebase login' manually when ready." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Create Firebase Project" -ForegroundColor Yellow
Write-Host ""
Write-Host "You have two options:" -ForegroundColor White
Write-Host "1. Create project via Firebase Console (Recommended for first time)" -ForegroundColor Cyan
Write-Host "   - Go to: https://console.firebase.google.com/" -ForegroundColor Gray
Write-Host "   - Click 'Add project'" -ForegroundColor Gray
Write-Host "   - Follow the wizard" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Create project via CLI (after login)" -ForegroundColor Cyan
Write-Host "   - Run: firebase projects:create PROJECT_ID" -ForegroundColor Gray
Write-Host ""

$projectId = Read-Host "Enter your Firebase Project ID (or press Enter to skip)"

if ($projectId) {
    Write-Host ""
    Write-Host "Step 3: Initialize Firestore" -ForegroundColor Yellow
    
    # Create .firebaserc if it doesn't exist
    if (-not (Test-Path ".firebaserc")) {
        Write-Host "Creating .firebaserc file..." -ForegroundColor Cyan
        @"
{
  "projects": {
    "default": "$projectId"
  }
}
"@ | Out-File -FilePath ".firebaserc" -Encoding utf8
    }
    
    Write-Host ""
    Write-Host "Initializing Firestore..." -ForegroundColor Cyan
    Write-Host "When prompted:" -ForegroundColor Yellow
    Write-Host "  - Select 'Firestore'" -ForegroundColor White
    Write-Host "  - Choose 'Start in production mode' (we'll set rules later)" -ForegroundColor White
    Write-Host ""
    
    $init = Read-Host "Run 'firebase init firestore' now? (y/n)"
    if ($init -eq "y" -or $init -eq "Y") {
        firebase init firestore
    }
    
    Write-Host ""
    Write-Host "Step 4: Generate Service Account Key" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To generate service account credentials:" -ForegroundColor White
    Write-Host "1. Go to: https://console.firebase.google.com/project/$projectId/settings/serviceaccounts/adminsdk" -ForegroundColor Cyan
    Write-Host "2. Click 'Generate new private key'" -ForegroundColor White
    Write-Host "3. Download the JSON file" -ForegroundColor White
    Write-Host "4. Copy the entire contents" -ForegroundColor White
    Write-Host "5. Add it to GitHub Secrets as FIREBASE_CREDENTIALS" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Or use this direct link:" -ForegroundColor Yellow
    Write-Host "https://console.firebase.google.com/project/$projectId/settings/serviceaccounts/adminsdk" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Step 5: Set Firestore Security Rules" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After Firestore is initialized, update security rules:" -ForegroundColor White
    Write-Host "1. Go to Firestore → Rules" -ForegroundColor Cyan
    Write-Host "2. Use the rules from docs/FIREBASE_SETUP.md" -ForegroundColor White
    Write-Host ""
    
    Write-Host "✅ Setup instructions complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Add FIREBASE_CREDENTIALS to GitHub Secrets" -ForegroundColor White
    Write-Host "2. Push code to trigger deployment" -ForegroundColor White
    Write-Host "3. Test API: curl http://EC2_IP:5000/health" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Manual Setup Instructions:" -ForegroundColor Yellow
    Write-Host "1. Go to https://console.firebase.google.com/" -ForegroundColor Cyan
    Write-Host "2. Create a new project" -ForegroundColor White
    Write-Host "3. Enable Firestore Database" -ForegroundColor White
    Write-Host "4. Generate service account key" -ForegroundColor White
    Write-Host "5. See docs/FIREBASE_SETUP.md for detailed steps" -ForegroundColor White
}

Write-Host ""

