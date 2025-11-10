# PowerShell script to add IAM permissions to GitHub Actions role
# Run this with AWS credentials that have IAM admin permissions

$ACCOUNT_ID = "843336589038"
$ROLE_NAME = "playmo-terraform-deploy"
$POLICY_NAME = "playmo-terraform-iam-permissions"

# Create the IAM policy document
$policyDocument = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Sid = "AllowIAMRoleManagement"
            Effect = "Allow"
            Action = @(
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:ListRoles",
                "iam:UpdateRole",
                "iam:UpdateAssumeRolePolicy",
                "iam:TagRole",
                "iam:UntagRole"
            )
            Resource = @(
                "arn:aws:iam::${ACCOUNT_ID}:role/playmo-smartdns-dns-only-*",
                "arn:aws:iam::${ACCOUNT_ID}:role/*lambda*"
            )
        },
        @{
            Sid = "AllowIAMPolicyManagement"
            Effect = "Allow"
            Action = @(
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:ListPolicies",
                "iam:ListPolicyVersions",
                "iam:TagPolicy",
                "iam:UntagPolicy"
            )
            Resource = @(
                "arn:aws:iam::${ACCOUNT_ID}:policy/playmo-smartdns-dns-only-*"
            )
        },
        @{
            Sid = "AllowIAMPolicyAttachment"
            Effect = "Allow"
            Action = @(
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListRolePolicies"
            )
            Resource = @(
                "arn:aws:iam::${ACCOUNT_ID}:role/playmo-smartdns-dns-only-*",
                "arn:aws:iam::${ACCOUNT_ID}:role/*lambda*"
            )
        },
        @{
            Sid = "AllowPassRoleToLambda"
            Effect = "Allow"
            Action = @(
                "iam:PassRole"
            )
            Resource = @(
                "arn:aws:iam::${ACCOUNT_ID}:role/playmo-smartdns-dns-only-*",
                "arn:aws:iam::${ACCOUNT_ID}:role/*lambda*"
            )
            Condition = @{
                StringEquals = @{
                    "iam:PassedToService" = "lambda.amazonaws.com"
                }
            }
        },
        @{
            Sid = "AllowListAllRoles"
            Effect = "Allow"
            Action = @(
                "iam:ListRoles"
            )
            Resource = "*"
        }
    )
} | ConvertTo-Json -Depth 10

# Save policy to temp file
$tempFile = [System.IO.Path]::GetTempFileName()
$policyDocument | Out-File -FilePath $tempFile -Encoding utf8

Write-Host "Creating IAM policy: ${POLICY_NAME}..." -ForegroundColor Cyan

try {
    # Try to create the policy
    $policyResult = aws iam create-policy `
        --policy-name $POLICY_NAME `
        --policy-document file://$tempFile `
        --description "Allows Terraform to create and manage IAM roles and policies for SmartDNS Lambda" `
        --tags Key=Purpose,Value="GitHub Actions Terraform Deployment" Key=Project,Value=playmo-smartdns `
        --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        $policy = $policyResult | ConvertFrom-Json
        $POLICY_ARN = $policy.Policy.Arn
        Write-Host "Policy created: ${POLICY_ARN}" -ForegroundColor Green
    } else {
        # Policy might already exist
        Write-Host "Policy may already exist. Getting existing policy ARN..." -ForegroundColor Yellow
        $existingPolicy = aws iam get-policy `
            --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}" `
            --output json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $policy = $existingPolicy | ConvertFrom-Json
            $POLICY_ARN = $policy.Policy.Arn
            Write-Host "Using existing policy: ${POLICY_ARN}" -ForegroundColor Yellow
        } else {
            Write-Host "Error: Could not create or find policy" -ForegroundColor Red
            Write-Host $existingPolicy -ForegroundColor Red
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            exit 1
        }
    }
    
    Write-Host "Attaching policy to role: ${ROLE_NAME}..." -ForegroundColor Cyan
    $attachResult = aws iam attach-role-policy `
        --role-name $ROLE_NAME `
        --policy-arn $POLICY_ARN 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Successfully attached policy to role!" -ForegroundColor Green
        Write-Host "Policy ARN: ${POLICY_ARN}" -ForegroundColor Green
    } else {
        # Check if it's already attached
        $attachedPolicies = aws iam list-attached-role-policies --role-name $ROLE_NAME --output json | ConvertFrom-Json
        $alreadyAttached = $attachedPolicies.AttachedPolicies | Where-Object { $_.PolicyArn -eq $POLICY_ARN }
        
        if ($alreadyAttached) {
            Write-Host "✅ Policy is already attached to the role!" -ForegroundColor Green
            Write-Host "Policy ARN: ${POLICY_ARN}" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to attach policy." -ForegroundColor Red
            Write-Host $attachResult -ForegroundColor Red
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            exit 1
        }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
} finally {
    # Cleanup
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Done! The GitHub Actions role now has IAM permissions." -ForegroundColor Green
Write-Host "You can now run your Terraform deployment from GitHub Actions." -ForegroundColor Green

