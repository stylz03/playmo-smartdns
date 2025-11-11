#!/bin/bash
# Check if old Elastic IP exists in AWS
# Run this to check if 3.151.46.11 still exists

OLD_IP="3.151.46.11"
REGION="us-east-2"

echo "Checking if old Elastic IP $OLD_IP exists..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS CLI not configured. Please configure it first."
    exit 1
fi

# Describe Elastic IPs
EIP_INFO=$(aws ec2 describe-addresses \
    --region $REGION \
    --filters "Name=public-ip,Values=$OLD_IP" \
    --query 'Addresses[0]' \
    --output json)

if [ "$EIP_INFO" != "null" ] && [ -n "$EIP_INFO" ]; then
    echo ""
    echo "✅ Old Elastic IP $OLD_IP EXISTS!"
    echo ""
    echo "Details:"
    echo "$EIP_INFO" | jq -r '
        "  Allocation ID: " + .AllocationId,
        "  Public IP: " + .PublicIp,
        "  Associated with: " + (.InstanceId // "Not associated"),
        "  Domain: " + .Domain
    '
    echo ""
    echo "We can associate this with the new instance!"
    exit 0
else
    echo ""
    echo "❌ Old Elastic IP $OLD_IP does NOT exist"
    echo ""
    echo "Using new IP: 3.151.75.152"
    exit 1
fi

