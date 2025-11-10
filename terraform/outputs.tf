output "ec2_public_ip" {
  description = "Public IP (Elastic IP) of the SmartDNS EC2 instance"
  value       = aws_eip.smartdns.public_ip
}

output "ec2_elastic_ip" {
  description = "Elastic IP address (static) of the SmartDNS EC2 instance"
  value       = aws_eip.smartdns.public_ip
}

output "lambda_function_url" {
  description = "Public URL of the SmartDNS Lambda function"
  value       = aws_lambda_function_url.whitelist.function_url
}

output "project_name" {
  description = "Project name used for tagging and resource naming"
  value       = var.project_name
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}
