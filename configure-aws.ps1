# AWS CLI Configuration Script
# This script helps you configure AWS CLI

Write-Host "AWS CLI Configuration" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""

Write-Host "You need AWS credentials to configure AWS CLI." -ForegroundColor Yellow
Write-Host ""
Write-Host "To get your credentials:" -ForegroundColor Yellow
Write-Host "1. Go to AWS Console -> IAM -> Users -> Your User -> Security Credentials" -ForegroundColor White
Write-Host "2. Click Create access key" -ForegroundColor White
Write-Host "3. Copy the Access Key ID and Secret Access Key" -ForegroundColor White
Write-Host ""

$accessKey = Read-Host "Enter your AWS Access Key ID"
$secretKey = Read-Host "Enter your AWS Secret Access Key" -AsSecureString
$region = Read-Host "Enter AWS Region (default: us-east-2)" 
$output = Read-Host "Enter output format (default: json)"

if ([string]::IsNullOrWhiteSpace($region)) {
    $region = "us-east-2"
}

if ([string]::IsNullOrWhiteSpace($output)) {
    $output = "json"
}

# Convert secure string to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretKey)
$plainSecretKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Configure AWS CLI
Write-Host ""
Write-Host "Configuring AWS CLI..." -ForegroundColor Green

aws configure set aws_access_key_id $accessKey
aws configure set aws_secret_access_key $plainSecretKey
aws configure set default.region $region
aws configure set default.output $output

Write-Host ""
Write-Host "AWS CLI configured successfully!" -ForegroundColor Green
Write-Host ""

# Test the configuration
Write-Host "Testing AWS connection..." -ForegroundColor Cyan
$identity = aws sts get-caller-identity 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "AWS credentials are working!" -ForegroundColor Green
    Write-Host $identity
} else {
    Write-Host "AWS credentials test failed:" -ForegroundColor Red
    Write-Host $identity
}

Write-Host ""
Write-Host "You can now use AWS CLI commands!" -ForegroundColor Green
