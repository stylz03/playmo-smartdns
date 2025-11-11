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
  region = var.aws_region
}

# Load streaming domains and US CDN IPs
locals {
  streaming_domains = jsondecode(file("${path.module}/../services.json"))
  domain_list       = [for k, v in local.streaming_domains : k if v]
  us_cdn_ips        = jsondecode(file("${path.module}/us-cdn-ips.json"))
  
  # Generate BIND9 zone configuration
  # Use static A records for domains with US CDN IPs, forward for others
  named_conf_local = join("\n\n", [
    for d in local.domain_list :
    contains(keys(local.us_cdn_ips), d) ? 
    <<EOT
zone "${d}" {
    type master;
    file "/etc/bind/zones/db.${replace(d, ".", "_")}";
};
EOT
    :
    <<EOT
zone "${d}" {
    type forward;
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; 1.0.0.1; };
    forward only;
};
EOT
  ])
  
  # Generate zone file contents for domains with static IPs
  zone_files = {
    for d in local.domain_list :
    d => contains(keys(local.us_cdn_ips), d) ? join("\n", [
      "$$TTL    604800",
      "@       IN      SOA     ns1.smartdns.local. admin.smartdns.local. (",
      "                        ${formatdate("YYYYMMDDHH", timestamp())}         ; Serial",
      "                        604800             ; Refresh",
      "                        86400              ; Retry",
      "                        2419200            ; Expire",
      "                        604800 )           ; Negative Cache TTL",
      ";",
      "@       IN      NS      ns1.smartdns.local.",
      join("\n", [for ip in local.us_cdn_ips[d] : "@       IN      A       ${ip}"])
    ]) : null
  }
  
  # BIND9 options optimized for US-based SmartDNS
  # Since EC2 is in us-east-2 (Ohio, USA), queries from BIND9 will appear
  # to come from US location, making upstream DNS return US IPs
  named_conf_options = <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
    # Ensure queries use the EC2's public IP (US-based)
    # This makes upstream DNS resolvers see queries from US location
    query-source address *;
    # No global forwarders - streaming domains use zone-specific forwarding
    # Non-streaming domains use normal recursive resolution
};
EOF
}

# Ubuntu AMI in us-east-2
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Default VPC + subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group: SSH + DNS
resource "aws_security_group" "smartdns_sg" {
  name   = "${var.project_name}-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.dns_cidr]
  }

  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.dns_cidr]
  }

  ingress {
    description = "API HTTP"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.api_cidr]
  }

  ingress {
    description = "Proxy HTTP (Squid)"
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Will be restricted by Squid ACLs based on whitelisted IPs
  }

  egress {
    description = "All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
  }
}

# Try to use existing Elastic IP first, create new if it doesn't exist
# Check for old IP: 3.151.46.11
data "aws_eip" "existing" {
  count   = var.use_existing_eip ? 1 : 0
  public_ip = var.existing_eip_address
}

# Elastic IP for static public IP (only create if not using existing)
resource "aws_eip" "smartdns" {
  count  = var.use_existing_eip ? 0 : 1
  domain = "vpc"
  
  lifecycle {
    prevent_destroy = false  # Allow destroy, but prefer to keep it
    create_before_destroy = false
  }
  
  tags = {
    Name = "${var.project_name}-eip"
    Project = var.project_name
  }
}

# Local to determine which EIP to use
locals {
  eip_allocation_id = var.use_existing_eip && length(data.aws_eip.existing) > 0 ? data.aws_eip.existing[0].id : (length(aws_eip.smartdns) > 0 ? aws_eip.smartdns[0].id : null)
  eip_public_ip     = var.use_existing_eip && length(data.aws_eip.existing) > 0 ? data.aws_eip.existing[0].public_ip : (length(aws_eip.smartdns) > 0 ? aws_eip.smartdns[0].public_ip : null)
}

# EC2 instance
resource "aws_instance" "smartdns" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids = [aws_security_group.smartdns_sg.id]
  key_name               = var.key_pair_name

  user_data = templatefile("${path.module}/user_data.sh", {
    NAMED_CONF_LOCAL     = local.named_conf_local
    NAMED_CONF_OPTIONS   = local.named_conf_options
    FIREBASE_CREDENTIALS = var.firebase_credentials != null ? var.firebase_credentials : ""
    LAMBDA_WHITELIST_URL = local.lambda_url
    SECURITY_GROUP_ID    = aws_security_group.smartdns_sg.id
  })
  
  # Lambda URL will be set after Lambda is created
  depends_on = [aws_lambda_function_url.whitelist]

  lifecycle {
    # Prevent unnecessary recreation - only recreate if AMI or instance type changes
    create_before_destroy = true
    ignore_changes = [
      # Ignore changes to user_data after initial creation (to allow manual updates)
      # Uncomment if you want to prevent user_data changes from triggering recreation:
      # user_data,
    ]
  }

  tags = {
    Name = "${var.project_name}-ec2"
  }
}

# Associate Elastic IP with EC2 instance
resource "aws_eip_association" "smartdns" {
  instance_id   = aws_instance.smartdns.id
  allocation_id = local.eip_allocation_id
  
  lifecycle {
    create_before_destroy = true
  }
}

# IAM + Lambda for IP whitelisting
locals {
  lambda_role_arn = var.lambda_iam_role_arn != null ? var.lambda_iam_role_arn : aws_iam_role.lambda_role[0].arn
  lambda_url      = var.lambda_whitelist_url != "" ? var.lambda_whitelist_url : aws_lambda_function_url.whitelist.function_url
}

resource "aws_iam_role" "lambda_role" {
  count = var.lambda_iam_role_arn == null ? 1 : 0
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "lambda_sg_policy" {
  count = var.lambda_iam_role_arn == null ? 1 : 0
  name        = "${var.project_name}-lambda-sg-policy"
  description = "Allow Lambda to manage SG ingress"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["ec2:AuthorizeSecurityGroupIngress","ec2:RevokeSecurityGroupIngress","ec2:DescribeSecurityGroups"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  count      = var.lambda_iam_role_arn == null ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.lambda_sg_policy[0].arn
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source {
    content = <<PY
import os, json, boto3
EC2_SG_ID = os.environ.get("EC2_SG_ID")
ec2 = boto3.client("ec2")
def lambda_handler(event, context):
    try:
        if isinstance(event, str): event = json.loads(event)
        ip = event.get("ip")
        if not ip: return {"status":"error","message":"missing ip"}
        
        # Whitelist DNS ports (UDP and TCP)
        for proto in ["udp", "tcp"]:
            try:
                ec2.authorize_security_group_ingress(
                    GroupId=EC2_SG_ID,
                    IpProtocol=proto,
                    FromPort=53, ToPort=53,
                    CidrIp=f"{ip}/32"
                )
            except Exception as e:
                if "already exists" not in str(e).lower():
                    raise
        
        # Whitelist proxy port (TCP)
        try:
            ec2.authorize_security_group_ingress(
                GroupId=EC2_SG_ID,
                IpProtocol="tcp",
                FromPort=3128, ToPort=3128,
                CidrIp=f"{ip}/32"
            )
        except Exception as e:
            if "already exists" not in str(e).lower():
                raise
        
        return {"status":"ok","message":f"whitelisted {ip} for DNS and proxy"}
    except Exception as e:
        return {"status":"error","message":str(e)}
PY
    filename = "lambda_function.py"
  }
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "whitelist" {
  function_name = "${var.project_name}-whitelist"
  role          = local.lambda_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 10
  environment {
    variables = {
      EC2_SG_ID = aws_security_group.smartdns_sg.id
    }
  }
}

resource "aws_lambda_function_url" "whitelist" {
  function_name      = aws_lambda_function.whitelist.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "allow_public_url" {
  statement_id           = "AllowPublicFunctionUrlInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.whitelist.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
