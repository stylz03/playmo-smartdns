#!/bin/bash
# Quick IP whitelist script
# Usage: bash whitelist-my-ip.sh YOUR_IP

if [ -z "$1" ]; then
    echo "Usage: $0 YOUR_IP_ADDRESS"
    echo "Example: $0 102.32.16.36"
    exit 1
fi

YOUR_IP="$1"
SG_ID="sg-0a9d5b82bfd5fe829"
LAMBDA_URL="https://wjpxg3gay5ba3scu2n3brfrsai0igxyt.lambda-url.us-east-2.on.aws/"

echo "Whitelisting IP: $YOUR_IP"

# Call Lambda function
echo "Calling Lambda function..."
curl -X POST "$LAMBDA_URL" \
  -H "Content-Type: application/json" \
  -d "{\"ip\": \"$YOUR_IP\"}" \
  -w "\nHTTP Status: %{http_code}\n"

echo ""
echo "✅ IP whitelisted! Try accessing streaming services now."

