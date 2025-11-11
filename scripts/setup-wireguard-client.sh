#!/bin/bash
# Complete setup script for WireGuard client
# Run this on EC2 to generate client configs with split-tunneling

set -e

CLIENT_NAME="${1:-client1}"

if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: $0 <client-name>"
    echo "Example: $0 client1"
    exit 1
fi

echo "=========================================="
echo "Setting up WireGuard Client: $CLIENT_NAME"
echo "=========================================="

# Check if WireGuard server is running
if ! systemctl is-active --quiet wg-quick@wg0; then
    echo "❌ WireGuard server is not running"
    echo "Start it with: sudo systemctl start wg-quick@wg0"
    exit 1
fi

# Get server info
if [ ! -f /etc/wireguard/server-info.txt ]; then
    echo "❌ Server info not found. WireGuard may not be installed."
    exit 1
fi

source /etc/wireguard/server-info.txt

echo ""
echo "Server Information:"
echo "  Public Key: $SERVER_PUBLIC_KEY"
echo "  Endpoint: $SERVER_ENDPOINT"
echo ""

# Download services.json if not present
if [ ! -f /tmp/services.json ]; then
    echo "Downloading services.json..."
    curl -s -f --max-time 30 \
        https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json \
        -o /tmp/services.json || echo "Warning: Could not download services.json"
fi

# Download scripts if not present
if [ ! -f /tmp/generate-streaming-ip-ranges.sh ]; then
    echo "Downloading generate-streaming-ip-ranges.sh..."
    curl -s -f --max-time 30 \
        https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/generate-streaming-ip-ranges.sh \
        -o /tmp/generate-streaming-ip-ranges.sh
    chmod +x /tmp/generate-streaming-ip-ranges.sh
fi

if [ ! -f /tmp/generate-wireguard-client-config.sh ]; then
    echo "Downloading generate-wireguard-client-config.sh..."
    curl -s -f --max-time 30 \
        https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/generate-wireguard-client-config.sh \
        -o /tmp/generate-wireguard-client-config.sh
    chmod +x /tmp/generate-wireguard-client-config.sh
fi

# Generate streaming IP ranges
echo ""
echo "Step 1: Generating streaming IP ranges..."
if [ -f /tmp/services.json ]; then
    /tmp/generate-streaming-ip-ranges.sh /tmp/services.json /tmp/streaming-ip-ranges.txt
else
    echo "❌ services.json not found. Cannot generate IP ranges."
    exit 1
fi

# Generate client config
echo ""
echo "Step 2: Generating client configuration..."
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# Get client IP
CLIENT_NUM=$(echo "$CLIENT_NAME" | grep -o '[0-9]\+' | head -1 || echo "2")
CLIENT_IP="10.0.0.$CLIENT_NUM"

# Read streaming IP ranges
ALLOWED_IPS=$(cat /tmp/streaming-ip-ranges.txt | grep -v '^#' | grep -v '^$' | tr '\n' ',' | sed 's/,$//')

# Generate client config
CLIENT_CONFIG_FILE="/tmp/${CLIENT_NAME}.conf"
cat > "$CLIENT_CONFIG_FILE" <<EOF
# WireGuard Client Configuration: $CLIENT_NAME
# Split-tunnel: Only streaming services route through VPN
# Generated: $(date)

[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24
DNS = 3.151.46.11  # SmartDNS for browsers (optional)

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

# Add client to WireGuard server
echo ""
echo "Step 3: Adding client to WireGuard server..."
sudo wg set wg0 peer "$CLIENT_PUBLIC_KEY" allowed-ips "$CLIENT_IP/32"

# Save client info
mkdir -p /etc/wireguard/clients
cat > "/etc/wireguard/clients/${CLIENT_NAME}.info" <<EOF
CLIENT_NAME=$CLIENT_NAME
CLIENT_PUBLIC_KEY=$CLIENT_PUBLIC_KEY
CLIENT_IP=$CLIENT_IP
ADDED_DATE=$(date)
EOF

# Generate QR code if qrencode is available
QR_CODE_FILE="/tmp/${CLIENT_NAME}.png"
QR_CODE_TXT="/tmp/${CLIENT_NAME}-qr.txt"
if command -v qrencode >/dev/null 2>&1; then
    echo ""
    echo "Step 4: Generating QR code..."
    qrencode -t PNG -o "$QR_CODE_FILE" < "$CLIENT_CONFIG_FILE"
    qrencode -t ANSIUTF8 < "$CLIENT_CONFIG_FILE" > "$QR_CODE_TXT" 2>/dev/null || true
    echo "✅ QR code generated: $QR_CODE_FILE"
    echo "✅ QR code (text): $QR_CODE_TXT"
fi

echo ""
echo "=========================================="
echo "✅ Client Setup Complete!"
echo "=========================================="
echo ""
echo "Client Configuration File: $CLIENT_CONFIG_FILE"
if [ -f "$QR_CODE_FILE" ]; then
    echo "QR Code (PNG): $QR_CODE_FILE"
    echo "QR Code (Text): $QR_CODE_TXT"
fi
echo ""
echo "Client Information:"
echo "  Name: $CLIENT_NAME"
echo "  IP: $CLIENT_IP"
echo "  Public Key: $CLIENT_PUBLIC_KEY"
echo ""
echo "Next Steps:"
echo "1. Share with customer:"
if [ -f "$QR_CODE_FILE" ]; then
    echo "   - QR Code (PNG): Download $QR_CODE_FILE"
    echo "   - QR Code (Text): View $QR_CODE_TXT"
    echo "   - Config File: Download $CLIENT_CONFIG_FILE"
else
    echo "   - Download config: $CLIENT_CONFIG_FILE"
fi
echo ""
echo "2. Customer imports into WireGuard app:"
echo "   - Android/iOS: Scan QR code or import file"
echo "   - Windows/Mac: Import config file"
echo ""
echo "3. Customer connects and tests streaming apps"
echo ""
echo "4. For browsers, set DNS to: 3.151.46.11"
echo ""
if [ -f "$QR_CODE_TXT" ]; then
    echo "=========================================="
    echo "QR Code (scan with WireGuard app):"
    echo "=========================================="
    cat "$QR_CODE_TXT"
    echo ""
fi
echo "Current WireGuard peers:"
sudo wg show

