#!/bin/bash
# Script to add IAM permissions to GitHub Actions role using AWS CLI
# Run this with AWS credentials that have IAM admin permissions

ACCOUNT_ID="843336589038"
ROLE_NAME="playmo-terraform-deploy"
POLICY_NAME="playmo-terraform-iam-permissions"

# Create the IAM policy
cat > /tmp/terraform-iam-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowIAMRoleManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:UpdateRole",
        "iam:UpdateAssumeRolePolicy",
        "iam:TagRole",
        "iam:UntagRole"
      ],
      "Resource": [
        "arn:aws:iam::${ACCOUNT_ID}:role/playmo-smartdns-dns-only-*",
        "arn:aws:iam::${ACCOUNT_ID}:role/*lambda*"
      ]
    },
    {
      "Sid": "AllowIAMPolicyManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicies",
        "iam:ListPolicyVersions",
        "iam:TagPolicy",
        "iam:UntagPolicy"
      ],
      "Resource": [
        "arn:aws:iam::${ACCOUNT_ID}:policy/playmo-smartdns-dns-only-*"
      ]
    },
    {
      "Sid": "AllowIAMPolicyAttachment",
      "Effect": "Allow",
      "Action": [
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies"
      ],
      "Resource": [
        "arn:aws:iam::${ACCOUNT_ID}:role/playmo-smartdns-dns-only-*",
        "arn:aws:iam::${ACCOUNT_ID}:role/*lambda*"
      ]
    },
    {
      "Sid": "AllowPassRoleToLambda",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:iam::${ACCOUNT_ID}:role/playmo-smartdns-dns-only-*",
        "arn:aws:iam::${ACCOUNT_ID}:role/*lambda*"
      ],
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "lambda.amazonaws.com"
        }
      }
    },
    {
      "Sid": "AllowListAllRoles",
      "Effect": "Allow",
      "Action": [
        "iam:ListRoles"
      ],
      "Resource": "*"
    }
  ]
}
EOF

echo "Creating IAM policy: ${POLICY_NAME}..."
POLICY_ARN=$(aws iam create-policy \
  --policy-name "${POLICY_NAME}" \
  --policy-document file:///tmp/terraform-iam-policy.json \
  --description "Allows Terraform to create and manage IAM roles and policies for SmartDNS Lambda" \
  --tags Key=Purpose,Value="GitHub Actions Terraform Deployment" Key=Project,Value=playmo-smartdns \
  --query 'Policy.Arn' \
  --output text 2>/dev/null)

if [ $? -eq 0 ]; then
  echo "Policy created: ${POLICY_ARN}"
else
  echo "Policy may already exist. Getting existing policy ARN..."
  POLICY_ARN=$(aws iam get-policy \
    --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}" \
    --query 'Policy.Arn' \
    --output text 2>/dev/null)
  
  if [ -z "$POLICY_ARN" ]; then
    echo "Error: Could not create or find policy"
    exit 1
  fi
  echo "Using existing policy: ${POLICY_ARN}"
fi

echo "Attaching policy to role: ${ROLE_NAME}..."
aws iam attach-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-arn "${POLICY_ARN}"

if [ $? -eq 0 ]; then
  echo "✅ Successfully attached policy to role!"
  echo "Policy ARN: ${POLICY_ARN}"
else
  echo "❌ Failed to attach policy. It may already be attached."
  exit 1
fi

# Cleanup
rm -f /tmp/terraform-iam-policy.json

echo ""
echo "Done! The GitHub Actions role now has IAM permissions."


