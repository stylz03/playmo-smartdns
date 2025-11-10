variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project_name" {
  type    = string
  default = "playmo-smartdns-dns-only"
}

variable "ssh_cidr" {
  type    = string
  default = "102.32.16.36/32" # replace with your admin IP
}

variable "dns_cidr" {
  type    = string
  default = "0.0.0.0/0" # tighten later, or use Lambda whitelisting
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_pair_name" {
  type    = string
  default = null
}

variable "lambda_iam_role_arn" {
  type        = string
  default     = null
  description = "Optional: ARN of existing IAM role for Lambda. If not provided, a new role will be created (requires iam:CreateRole permission)"
}

variable "api_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR block for API access (port 5000). Consider restricting this for production."
}

variable "firebase_credentials" {
  type        = string
  default     = null
  sensitive   = true
  description = "Firebase Admin SDK service account credentials (JSON string). Should be provided via GitHub Secrets."
}

variable "lambda_whitelist_url" {
  type        = string
  default     = ""
  description = "Lambda function URL for IP whitelisting. Will be set automatically from Lambda output."
}