# Delete Firebase Project
# WARNING: This is permanent and cannot be undone!

$npmPath = "C:\Users\tinas\AppData\Roaming\npm"
$env:Path += ";$npmPath"

Write-Host "Delete Firebase Project" -ForegroundColor Red
Write-Host "======================" -ForegroundColor Red
Write-Host ""
Write-Host "WARNING: Deleting a project is PERMANENT and cannot be undone!" -ForegroundColor Yellow
Write-Host "All data, databases, and configurations will be lost." -ForegroundColor Yellow
Write-Host ""

# List projects first
Write-Host "Your Firebase projects:" -ForegroundColor Cyan
firebase projects:list

Write-Host ""
$projectId = Read-Host "Enter the Project ID to delete (or press Enter to cancel)"

if ([string]::IsNullOrWhiteSpace($projectId)) {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "You are about to delete project: $projectId" -ForegroundColor Red
Write-Host "This action CANNOT be undone!" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Type the project ID again to confirm deletion (or 'cancel' to abort)"

if ($confirm -eq "cancel" -or $confirm -ne $projectId) {
    Write-Host "Deletion cancelled." -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "Deleting project via CLI..." -ForegroundColor Yellow
Write-Host "Note: CLI deletion may not work. You may need to delete via web console." -ForegroundColor Yellow
Write-Host ""

# Try to delete via CLI (may not work, Firebase often requires web console)
firebase projects:delete $projectId --force

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Project deletion initiated!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "CLI deletion may not be supported. Please delete via web console:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Go to: https://console.firebase.google.com/project/$projectId/settings/general" -ForegroundColor Cyan
    Write-Host "2. Scroll to the bottom" -ForegroundColor White
    Write-Host "3. Click 'Delete project'" -ForegroundColor White
    Write-Host "4. Type the project ID to confirm" -ForegroundColor White
    Write-Host "5. Click 'Delete'" -ForegroundColor White
}

Write-Host ""

