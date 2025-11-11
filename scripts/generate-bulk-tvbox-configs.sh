#!/bin/bash
# Generate multiple WireGuard configs for TV boxes
# Usage: ./generate-bulk-tvbox-configs.sh <customer-list-file>
# Customer list format: one customer name per line

set -e

CUSTOMER_LIST="${1:-/dev/stdin}"

if [ ! -f "$CUSTOMER_LIST" ] && [ "$CUSTOMER_LIST" != "/dev/stdin" ]; then
    echo "Usage: $0 <customer-list-file>"
    echo "Example: $0 customers.txt"
    echo ""
    echo "Customer list format (one per line):"
    echo "  customer1"
    echo "  customer2"
    echo "  customer3"
    exit 1
fi

echo "=========================================="
echo "Bulk Generating TV Box Configs"
echo "=========================================="
echo ""

# Check if WireGuard server is running
if ! systemctl is-active --quiet wg-quick@wg0; then
    echo "❌ WireGuard server is not running"
    exit 1
fi

# Check if generate script exists
GENERATE_SCRIPT="/usr/local/bin/generate-tvbox-wireguard-config.sh"
if [ ! -f "$GENERATE_SCRIPT" ]; then
    # Try local script
    GENERATE_SCRIPT="./scripts/generate-tvbox-wireguard-config.sh"
    if [ ! -f "$GENERATE_SCRIPT" ]; then
        echo "❌ Generate script not found"
        exit 1
    fi
fi

# Create output directory
OUTPUT_DIR="/tmp/tvbox-configs-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# Read customer list
CUSTOMERS=()
if [ "$CUSTOMER_LIST" = "/dev/stdin" ]; then
    echo "Enter customer names (one per line, Ctrl+D when done):"
    while IFS= read -r line; do
        [ -n "$line" ] && CUSTOMERS+=("$line")
    done
else
    while IFS= read -r line; do
        [ -n "$line" ] && CUSTOMERS+=("$line")
    done < "$CUSTOMER_LIST"
fi

if [ ${#CUSTOMERS[@]} -eq 0 ]; then
    echo "❌ No customers found"
    exit 1
fi

echo "Found ${#CUSTOMERS[@]} customers"
echo "Generating configs..."
echo ""

SUCCESS=0
FAILED=0

for CUSTOMER in "${CUSTOMERS[@]}"; do
    echo "Processing: $CUSTOMER"
    
    # Generate config
    if bash "$GENERATE_SCRIPT" "$CUSTOMER" "dns-only" > /dev/null 2>&1; then
        # Copy config to output directory
        CONFIG_FILE="/tmp/${CUSTOMER}.conf"
        if [ -f "$CONFIG_FILE" ]; then
            cp "$CONFIG_FILE" "$OUTPUT_DIR/${CUSTOMER}.conf"
            
            # Generate QR code if available
            if command -v qrencode >/dev/null 2>&1; then
                QR_FILE="/tmp/${CUSTOMER}.png"
                if [ -f "$QR_FILE" ]; then
                    cp "$QR_FILE" "$OUTPUT_DIR/${CUSTOMER}.png"
                fi
            fi
            
            echo "  ✅ Generated: $OUTPUT_DIR/${CUSTOMER}.conf"
            ((SUCCESS++))
        else
            echo "  ❌ Config file not found"
            ((FAILED++))
        fi
    else
        echo "  ❌ Failed to generate config"
        ((FAILED++))
    fi
done

echo ""
echo "=========================================="
echo "✅ Bulk Generation Complete!"
echo "=========================================="
echo ""
echo "Output Directory: $OUTPUT_DIR"
echo "Success: $SUCCESS"
echo "Failed: $FAILED"
echo ""
echo "Files generated:"
ls -lh "$OUTPUT_DIR" | tail -n +2
echo ""
echo "To download all configs:"
echo "  scp -r ubuntu@3.151.46.11:$OUTPUT_DIR ./tvbox-configs"
echo ""
echo "Or download individually:"
for CUSTOMER in "${CUSTOMERS[@]}"; do
    if [ -f "$OUTPUT_DIR/${CUSTOMER}.conf" ]; then
        echo "  $OUTPUT_DIR/${CUSTOMER}.conf"
    fi
done
echo ""

