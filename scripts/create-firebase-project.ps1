# Create New Firebase Project for Playmo SmartDNS

$npmPath = "C:\Users\tinas\AppData\Roaming\npm"
$env:Path += ";$npmPath"

Write-Host "Creating New Firebase Project for Playmo SmartDNS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Project ID must be globally unique and can only contain lowercase letters, numbers, and hyphens
$projectId = Read-Host "Enter a unique Project ID (e.g., playmo-smartdns or playmo-smartdns-2025)"

if ([string]::IsNullOrWhiteSpace($projectId)) {
    $projectId = "playmo-smartdns"
    Write-Host "Using default: $projectId" -ForegroundColor Yellow
}

# Validate project ID format
if ($projectId -notmatch '^[a-z0-9-]+$') {
    Write-Host "Error: Project ID can only contain lowercase letters, numbers, and hyphens" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Creating Firebase project: $projectId" -ForegroundColor Yellow
Write-Host "This may take a minute..." -ForegroundColor White
Write-Host ""

# Create the project
try {
    firebase projects:create $projectId --display-name "Playmo SmartDNS"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Project created successfully!" -ForegroundColor Green
        Write-Host ""
        
        # Update .firebaserc
        Write-Host "Updating .firebaserc file..." -ForegroundColor Yellow
        @"
{
  "projects": {
    "default": "$projectId"
  }
}
"@ | Out-File -FilePath ".firebaserc" -Encoding utf8
        
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Initialize Firestore:" -ForegroundColor White
        Write-Host "   .\scripts\init-firestore.ps1" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Or manually in web console:" -ForegroundColor White
        Write-Host "   https://console.firebase.google.com/project/$projectId/firestore" -ForegroundColor Gray
        Write-Host "   Click 'Create database'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "3. Generate service account key:" -ForegroundColor White
        Write-Host "   https://console.firebase.google.com/project/$projectId/settings/serviceaccounts/adminsdk" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "Project creation may have failed or project ID already exists." -ForegroundColor Yellow
        Write-Host "Check the output above for details." -ForegroundColor White
        Write-Host ""
        Write-Host "You can also create it via web console:" -ForegroundColor Cyan
        Write-Host "https://console.firebase.google.com/" -ForegroundColor Gray
    }
} catch {
    Write-Host ""
    Write-Host "Error creating project: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Create via web console" -ForegroundColor Yellow
    Write-Host "1. Go to: https://console.firebase.google.com/" -ForegroundColor Cyan
    Write-Host "2. Click 'Add project'" -ForegroundColor White
    Write-Host "3. Enter project name: Playmo SmartDNS" -ForegroundColor White
    Write-Host "4. Project ID will be auto-generated or you can customize it" -ForegroundColor White
}

Write-Host ""

