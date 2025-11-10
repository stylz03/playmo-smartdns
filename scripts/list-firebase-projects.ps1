# List all Firebase projects

$npmPath = "C:\Users\tinas\AppData\Roaming\npm"
$env:Path += ";$npmPath"

Write-Host "Firebase Projects" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host ""

firebase projects:list

Write-Host ""
Write-Host "To delete a project:" -ForegroundColor Yellow
Write-Host "1. Go to: https://console.firebase.google.com/" -ForegroundColor White
Write-Host "2. Click on the project you want to delete" -ForegroundColor White
Write-Host "3. Go to Project Settings (gear icon)" -ForegroundColor White
Write-Host "4. Scroll down and click 'Delete project'" -ForegroundColor White
Write-Host ""
Write-Host "Or use the script: .\scripts\delete-firebase-project.ps1" -ForegroundColor Cyan

