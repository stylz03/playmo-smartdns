#!/bin/bash
# Generate QR code for existing WireGuard client config
# Usage: ./generate-qr-code.sh <client-name> [config-file]

set -e

CLIENT_NAME="${1:-}"
CONFIG_FILE="${2:-}"

if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: $0 <client-name> [config-file]"
    echo "Example: $0 client1 /tmp/client1.conf"
    exit 1
fi

# Find config file if not provided
if [ -z "$CONFIG_FILE" ]; then
    if [ -f "/tmp/${CLIENT_NAME}.conf" ]; then
        CONFIG_FILE="/tmp/${CLIENT_NAME}.conf"
    elif [ -f "/etc/wireguard/clients/${CLIENT_NAME}.conf" ]; then
        CONFIG_FILE="/etc/wireguard/clients/${CLIENT_NAME}.conf"
    else
        echo "Error: Config file not found for $CLIENT_NAME"
        echo "Please specify the config file path"
        exit 1
    fi
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Check if qrencode is installed
if ! command -v qrencode >/dev/null 2>&1; then
    echo "Error: qrencode is not installed"
    echo "Install with: sudo apt-get install qrencode"
    exit 1
fi

# Generate QR codes
QR_CODE_PNG="/tmp/${CLIENT_NAME}.png"
QR_CODE_TXT="/tmp/${CLIENT_NAME}-qr.txt"
QR_CODE_SVG="/tmp/${CLIENT_NAME}.svg"

echo "Generating QR codes for $CLIENT_NAME..."
echo "Config file: $CONFIG_FILE"

# PNG QR code
qrencode -t PNG -o "$QR_CODE_PNG" -s 10 < "$CONFIG_FILE"
echo "✅ PNG QR code: $QR_CODE_PNG"

# Text QR code (for terminal display)
qrencode -t ANSIUTF8 < "$CONFIG_FILE" > "$QR_CODE_TXT" 2>/dev/null || \
qrencode -t UTF8 < "$CONFIG_FILE" > "$QR_CODE_TXT" 2>/dev/null || true
if [ -f "$QR_CODE_TXT" ]; then
    echo "✅ Text QR code: $QR_CODE_TXT"
fi

# SVG QR code (scalable, good for web)
if qrencode -t SVG -o "$QR_CODE_SVG" < "$CONFIG_FILE" 2>/dev/null; then
    echo "✅ SVG QR code: $QR_CODE_SVG"
fi

echo ""
echo "=========================================="
echo "QR Codes Generated"
echo "=========================================="
echo ""
echo "Files created:"
echo "  - PNG: $QR_CODE_PNG (best for sharing/download)"
echo "  - SVG: $QR_CODE_SVG (scalable, good for web)"
if [ -f "$QR_CODE_TXT" ]; then
    echo "  - Text: $QR_CODE_TXT (for terminal display)"
fi
echo ""
echo "To share with customer:"
echo "1. Download QR code image: $QR_CODE_PNG"
echo "2. Customer scans with WireGuard app"
echo "3. Or share config file: $CONFIG_FILE"
echo ""
if [ -f "$QR_CODE_TXT" ]; then
    echo "QR Code (scan with WireGuard app):"
    echo "=========================================="
    cat "$QR_CODE_TXT"
    echo ""
fi

