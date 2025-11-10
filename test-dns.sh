#!/bin/bash
# DNS Test Script for SmartDNS
# This script tests DNS resolution against your SmartDNS EC2 instance

echo "🔍 SmartDNS Testing Script"
echo "=========================="
echo ""

# Get EC2 public IP from Terraform
if [ -f "terraform/terraform.tfstate" ]; then
    EC2_IP=$(cd terraform && terraform output -raw ec2_public_ip 2>/dev/null | grep -v "::debug::" | grep -v "Terraform exited" | grep -v "stdout:" | grep -v "stderr:" | grep -v "exitcode:" | tr -d '\n\r' | head -c 50)
    
    # Extract IP if it contains one
    if [[ "$EC2_IP" =~ ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}) ]]; then
        EC2_IP="${BASH_REMATCH[1]}"
    fi
else
    echo "⚠️  Terraform state not found. Please provide EC2 public IP:"
    read -p "EC2 Public IP: " EC2_IP
fi

if [ -z "$EC2_IP" ] || [[ ! "$EC2_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid or missing EC2 IP address: $EC2_IP"
    exit 1
fi

echo "📍 Testing against EC2 instance: $EC2_IP"
echo ""

# Test domains from services.json
TEST_DOMAINS=(
    "netflix.com"
    "disneyplus.com"
    "hulu.com"
    "hbomax.com"
    "peacocktv.com"
    "youtube.com"  # This should NOT be forwarded (not in services.json)
)

echo "Testing streaming domains (should be forwarded to 8.8.8.8/1.1.1.1):"
echo "-------------------------------------------------------------------"

for domain in "${TEST_DOMAINS[@]}"; do
    echo -n "Testing $domain... "
    
    # Test DNS resolution
    result=$(dig +short +timeout=3 $domain @$EC2_IP 2>&1)
    
    if [ -z "$result" ] || [[ "$result" == *"connection timed out"* ]] || [[ "$result" == *"no servers could be reached"* ]]; then
        echo "❌ FAILED - No response or timeout"
    elif [[ "$result" == *"Invalid"* ]] || [[ "$result" == *"error"* ]]; then
        echo "❌ FAILED - $result"
    else
        # Get first IP from result
        first_ip=$(echo "$result" | head -n1 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n1)
        if [ -n "$first_ip" ]; then
            echo "✅ OK - Resolved to $first_ip"
        else
            echo "⚠️  WARNING - Got response but no IP: $result"
        fi
    fi
done

echo ""
echo "Testing non-streaming domain (should use normal DNS):"
echo "-----------------------------------------------------"
echo -n "Testing google.com... "
result=$(dig +short +timeout=3 google.com @$EC2_IP 2>&1)
if [ -z "$result" ] || [[ "$result" == *"connection timed out"* ]]; then
    echo "❌ FAILED"
else
    first_ip=$(echo "$result" | head -n1 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n1)
    if [ -n "$first_ip" ]; then
        echo "✅ OK - Resolved to $first_ip"
    else
        echo "⚠️  WARNING - $result"
    fi
fi

echo ""
echo "=========================="
echo "✅ DNS Testing Complete!"
echo ""
echo "💡 To use this DNS server:"
echo "   Set your device DNS to: $EC2_IP"
echo ""

