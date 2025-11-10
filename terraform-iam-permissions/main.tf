terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# Data source to get the existing GitHub Actions role
data "aws_iam_role" "github_actions_role" {
  name = "playmo-terraform-deploy"
}

# Policy document for IAM permissions needed by Terraform
data "aws_iam_policy_document" "terraform_iam_permissions" {
  statement {
    sid    = "AllowIAMRoleManagement"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:ListRoles",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole"
    ]
    resources = [
      "arn:aws:iam::843336589038:role/playmo-smartdns-dns-only-*",
      "arn:aws:iam::843336589038:role/*lambda*"
    ]
  }

  statement {
    sid    = "AllowIAMPolicyManagement"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]
    resources = [
      "arn:aws:iam::843336589038:policy/playmo-smartdns-dns-only-*"
    ]
  }

  statement {
    sid    = "AllowIAMPolicyAttachment"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies"
    ]
    resources = [
      "arn:aws:iam::843336589038:role/playmo-smartdns-dns-only-*",
      "arn:aws:iam::843336589038:role/*lambda*"
    ]
  }

  statement {
    sid    = "AllowPassRoleToLambda"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::843336589038:role/playmo-smartdns-dns-only-*",
      "arn:aws:iam::843336589038:role/*lambda*"
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowListAllRoles"
    effect = "Allow"
    actions = [
      "iam:ListRoles"
    ]
    resources = ["*"]
  }
}

# Create the policy
resource "aws_iam_policy" "terraform_iam_permissions" {
  name        = "playmo-terraform-iam-permissions"
  description = "Allows Terraform to create and manage IAM roles and policies for SmartDNS Lambda"
  policy      = data.aws_iam_policy_document.terraform_iam_permissions.json

  tags = {
    Purpose = "GitHub Actions Terraform Deployment"
    Project = "playmo-smartdns"
  }
}

# Attach the policy to the GitHub Actions role
resource "aws_iam_role_policy_attachment" "attach_iam_permissions" {
  role       = data.aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.terraform_iam_permissions.arn
}

output "policy_arn" {
  description = "ARN of the created IAM policy"
  value       = aws_iam_policy.terraform_iam_permissions.arn
}

output "role_name" {
  description = "Name of the role the policy was attached to"
  value       = data.aws_iam_role.github_actions_role.name
}


