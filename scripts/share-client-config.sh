#!/bin/bash
# Easy way to share WireGuard client config with customers
# Generates QR code and provides sharing options
# Usage: ./share-client-config.sh <client-name>

set -e

CLIENT_NAME="${1:-client1}"
CONFIG_FILE="/tmp/${CLIENT_NAME}.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo "Run setup-wireguard-client.sh first to create the client"
    exit 1
fi

# Generate QR code if not exists
QR_CODE_PNG="/tmp/${CLIENT_NAME}.png"
if [ ! -f "$QR_CODE_PNG" ]; then
    if command -v qrencode >/dev/null 2>&1; then
        echo "Generating QR code..."
        qrencode -t PNG -o "$QR_CODE_PNG" -s 10 < "$CONFIG_FILE"
    else
        echo "Warning: qrencode not installed. Install with: sudo apt-get install qrencode"
    fi
fi

# Get EC2 public IP
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "3.151.46.11")

echo "=========================================="
echo "Share WireGuard Config: $CLIENT_NAME"
echo "=========================================="
echo ""
echo "Method 1: QR Code (Easiest for Mobile)"
echo "----------------------------------------"
if [ -f "$QR_CODE_PNG" ]; then
    echo "✅ QR Code file: $QR_CODE_PNG"
    echo ""
    echo "To share:"
    echo "1. Download QR code: scp ubuntu@${EC2_IP}:$QR_CODE_PNG ."
    echo "2. Send QR code image to customer"
    echo "3. Customer scans with WireGuard app (Android/iOS)"
    echo ""
    # Display QR code in terminal if possible
    if command -v qrencode >/dev/null 2>&1; then
        echo "QR Code (scan with WireGuard app):"
        echo "----------------------------------------"
        qrencode -t ANSIUTF8 < "$CONFIG_FILE" 2>/dev/null || \
        qrencode -t UTF8 < "$CONFIG_FILE" 2>/dev/null || true
        echo ""
    fi
else
    echo "❌ QR code not available (install qrencode)"
fi

echo "Method 2: Config File"
echo "----------------------------------------"
echo "✅ Config file: $CONFIG_FILE"
echo ""
echo "To share:"
echo "1. Download config: scp ubuntu@${EC2_IP}:$CONFIG_FILE ."
echo "2. Send config file to customer"
echo "3. Customer imports into WireGuard app"
echo ""

echo "Method 3: Direct Link (if web server available)"
echo "----------------------------------------"
echo "If you set up a simple web server, customers can download:"
echo "  http://${EC2_IP}/wireguard/${CLIENT_NAME}.conf"
echo "  http://${EC2_IP}/wireguard/${CLIENT_NAME}.png"
echo ""

echo "Method 4: Copy-Paste Config"
echo "----------------------------------------"
echo "View config content:"
echo "  cat $CONFIG_FILE"
echo "Customer can copy-paste into WireGuard app"
echo ""

echo "=========================================="
echo "Customer Instructions"
echo "=========================================="
echo ""
echo "For Android/iOS:"
echo "1. Open WireGuard app"
echo "2. Tap + button"
echo "3. Scan QR code OR import from file"
echo "4. Tap 'Add'"
echo "5. Toggle to connect"
echo ""
echo "For Windows/Mac:"
echo "1. Open WireGuard client"
echo "2. Click 'Import tunnel'"
echo "3. Select config file"
echo "4. Click 'Save'"
echo "5. Click to connect"
echo ""
echo "After connecting:"
echo "- Test streaming apps (Netflix, Disney+, Hulu)"
echo "- Normal web traffic stays on regular connection"
echo "- For browsers, set DNS to: 3.151.46.11"
echo ""

