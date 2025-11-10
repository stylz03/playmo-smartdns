#!/bin/bash
# Update Lambda URL in EC2 instance after deployment
# This script can be run manually or via GitHub Actions

INSTANCE_ID="${1:-}"
LAMBDA_URL="${2:-}"

if [ -z "$INSTANCE_ID" ] || [ -z "$LAMBDA_URL" ]; then
    echo "Usage: $0 <instance-id> <lambda-url>"
    exit 1
fi

echo "Updating Lambda URL on instance $INSTANCE_ID..."

# Update systemd service environment
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[
        'sudo systemctl stop playmo-smartdns-api',
        'sudo sed -i \"s|Environment=\"LAMBDA_WHITELIST_URL=.*|Environment=\"LAMBDA_WHITELIST_URL=$LAMBDA_URL\"|\" /etc/systemd/system/playmo-smartdns-api.service',
        'sudo systemctl daemon-reload',
        'sudo systemctl start playmo-smartdns-api'
    ]" \
    --region us-east-2

echo "Lambda URL update command sent. Check instance logs for status."

