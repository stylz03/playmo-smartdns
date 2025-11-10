# Create New Firebase Project for Playmo SmartDNS (with better error handling)

$npmPath = "C:\Users\tinas\AppData\Roaming\npm"
$env:Path += ";$npmPath"

Write-Host "Creating New Firebase Project for Playmo SmartDNS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Try different project ID options
$suggestedIds = @(
    "playmo-smartdns-$(Get-Date -Format 'yyyyMMdd')",
    "playmo-smartdns-dns",
    "playmo-smartdns-service",
    "smartdns-playmo"
)

Write-Host "Suggested Project IDs (choose one or enter your own):" -ForegroundColor Yellow
for ($i = 0; $i -lt $suggestedIds.Length; $i++) {
    Write-Host "  $($i+1). $($suggestedIds[$i])" -ForegroundColor White
}
Write-Host ""

$choice = Read-Host "Enter number (1-4) or type your own Project ID"

if ($choice -match '^[1-4]$') {
    $projectId = $suggestedIds[[int]$choice - 1]
} else {
    $projectId = $choice
}

if ([string]::IsNullOrWhiteSpace($projectId)) {
    $projectId = $suggestedIds[0]
    Write-Host "Using default: $projectId" -ForegroundColor Yellow
}

# Validate project ID format
if ($projectId -notmatch '^[a-z0-9-]+$') {
    Write-Host "Error: Project ID can only contain lowercase letters, numbers, and hyphens" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Attempting to create project: $projectId" -ForegroundColor Yellow
Write-Host ""

# Try to create the project
$result = firebase projects:create $projectId --display-name "Playmo SmartDNS" 2>&1

if ($LASTEXITCODE -eq 0 -or $result -match "already exists" -or $result -match "Created")) {
    Write-Host ""
    Write-Host "Project setup complete!" -ForegroundColor Green
    Write-Host ""
    
    # Update .firebaserc
    Write-Host "Updating .firebaserc file..." -ForegroundColor Yellow
    @"
{
  "projects": {
    "default": "$projectId"
  }
}
"@ | Out-File -FilePath ".firebaserc" -Encoding utf8 -Force
    
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Enable Firestore in web console:" -ForegroundColor White
    Write-Host "   https://console.firebase.google.com/project/$projectId/firestore" -ForegroundColor Gray
    Write-Host "   Click 'Create database' -> Start in production mode" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Generate service account key:" -ForegroundColor White
    Write-Host "   https://console.firebase.google.com/project/$projectId/settings/serviceaccounts/adminsdk" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Add to GitHub Secrets as FIREBASE_CREDENTIALS" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Project creation via CLI failed. Creating via web console is recommended." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please create the project manually:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://console.firebase.google.com/" -ForegroundColor White
    Write-Host "2. Click 'Add project'" -ForegroundColor White
    Write-Host "3. Project name: Playmo SmartDNS" -ForegroundColor White
    Write-Host "4. Project ID: $projectId (or let it auto-generate)" -ForegroundColor White
    Write-Host "5. Follow the wizard" -ForegroundColor White
    Write-Host ""
    Write-Host "After creating, update .firebaserc with your project ID:" -ForegroundColor Yellow
    Write-Host "  firebase use YOUR_PROJECT_ID" -ForegroundColor Gray
}

Write-Host ""

