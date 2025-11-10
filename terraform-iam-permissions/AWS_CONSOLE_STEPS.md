# Add IAM Permissions via AWS Console

Since you're using IAM roles (not users), follow these steps in the AWS Console:

## Step 1: Create the IAM Policy

1. In the AWS Console, go to **IAM** → **Policies** (in the left sidebar)
2. Click the orange **"Create policy"** button
3. Click the **"JSON"** tab
4. Delete the default content and paste this policy:

```json
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
        "arn:aws:iam::843336589038:role/playmo-smartdns-dns-only-*",
        "arn:aws:iam::843336589038:role/*lambda*"
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
        "arn:aws:iam::843336589038:policy/playmo-smartdns-dns-only-*"
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
        "arn:aws:iam::843336589038:role/playmo-smartdns-dns-only-*",
        "arn:aws:iam::843336589038:role/*lambda*"
      ]
    },
    {
      "Sid": "AllowPassRoleToLambda",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:iam::843336589038:role/playmo-smartdns-dns-only-*",
        "arn:aws:iam::843336589038:role/*lambda*"
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
```

5. Click **"Next"**
6. Name the policy: `playmo-terraform-iam-permissions`
7. (Optional) Add description: "Allows Terraform to create and manage IAM roles and policies for SmartDNS Lambda"
8. Click **"Create policy"**

## Step 2: Attach Policy to the Role

1. In the AWS Console, go to **IAM** → **Roles** (in the left sidebar)
2. Search for or find the role: `playmo-terraform-deploy`
3. Click on the role name to open it
4. Click the **"Add permissions"** dropdown button
5. Select **"Attach policies"**
6. In the search box, type: `playmo-terraform-iam-permissions`
7. Check the box next to the policy you just created
8. Click **"Add permissions"** at the bottom

## Step 3: Verify

1. Still on the role page, scroll down to the **"Permissions"** section
2. You should see `playmo-terraform-iam-permissions` listed under "Permissions policies"
3. ✅ Done! Your GitHub Actions workflow should now be able to create IAM resources

## That's it!

Now when your GitHub Actions workflow runs, it will have permission to:
- Create IAM roles for Lambda
- Create IAM policies
- Attach policies to roles
- Pass roles to Lambda service

You can now push your code and the Terraform deployment should work!

