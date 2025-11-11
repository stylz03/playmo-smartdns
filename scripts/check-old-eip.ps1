# Check if old Elastic IP exists in AWS
# Run this to check if 3.151.46.11 still exists

$oldIP = "3.151.46.11"
$region = "us-east-2"

Write-Host "Checking if old Elastic IP $oldIP exists..." -ForegroundColor Cyan

try {
    # Check if AWS CLI is configured
    $awsCheck = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "AWS CLI not configured. Please configure it first." -ForegroundColor Red
        exit 1
    }

    # Describe all Elastic IPs in the region
    $eips = aws ec2 describe-addresses --region $region --query "Addresses[?PublicIp=='$oldIP']" --output json | ConvertFrom-Json

    if ($eips.Count -gt 0) {
        Write-Host "`n✅ Old Elastic IP $oldIP EXISTS!" -ForegroundColor Green
        Write-Host "`nDetails:" -ForegroundColor Cyan
        $eips | ForEach-Object {
            Write-Host "  Allocation ID: $($_.AllocationId)" -ForegroundColor White
            Write-Host "  Public IP: $($_.PublicIp)" -ForegroundColor White
            Write-Host "  Associated with: $($_.InstanceId)" -ForegroundColor White
            Write-Host "  Domain: $($_.Domain)" -ForegroundColor White
        }
        Write-Host "`nWe can associate this with the new instance!" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Old Elastic IP $oldIP does NOT exist" -ForegroundColor Red
        Write-Host "`nUsing new IP: 3.151.75.152" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error checking Elastic IP: $_" -ForegroundColor Red
}

