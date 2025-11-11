#!/bin/bash
# Generate WireGuard client configuration with split-tunneling
# Only routes streaming service IPs through VPN
# Usage: ./generate-wireguard-client-config.sh <client-name> [streaming-ip-ranges-file]

set -e

CLIENT_NAME="${1:-client1}"
STREAMING_IPS_FILE="${2:-streaming-ip-ranges.txt}"

if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: $0 <client-name> [streaming-ip-ranges-file]"
    echo "Example: $0 client1 streaming-ip-ranges.txt"
    exit 1
fi

# Check if streaming IP ranges file exists
if [ ! -f "$STREAMING_IPS_FILE" ]; then
    echo "⚠️  Warning: $STREAMING_IPS_FILE not found"
    echo "Generating streaming IP ranges first..."
    if [ -f "services.json" ]; then
        ./generate-streaming-ip-ranges.sh services.json "$STREAMING_IPS_FILE" || {
            echo "Error: Failed to generate streaming IP ranges"
            exit 1
        }
    else
        echo "Error: services.json not found. Cannot generate IP ranges."
        exit 1
    fi
fi

# Generate client private key
if ! command -v wg >/dev/null 2>&1; then
    echo "Error: WireGuard tools not installed."
    echo "Install with: apt-get install wireguard-tools"
    exit 1
fi

CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# Generate client IP (use client number from name)
CLIENT_NUM=$(echo "$CLIENT_NAME" | grep -o '[0-9]\+' | head -1 || echo "2")
CLIENT_IP="10.0.0.$CLIENT_NUM"

# Read streaming IP ranges and format for AllowedIPs
ALLOWED_IPS=$(cat "$STREAMING_IPS_FILE" | grep -v '^#' | grep -v '^$' | tr '\n' ',' | sed 's/,$//')

# Get server info (if available from server)
if [ -f "/etc/wireguard/server-info.txt" ]; then
    source /etc/wireguard/server-info.txt
else
    # Defaults (user should update these)
    SERVER_PUBLIC_KEY="<SERVER_PUBLIC_KEY>"
    SERVER_ENDPOINT="<EC2_PUBLIC_IP>:51820"
fi

# Generate client config
CLIENT_CONFIG_FILE="${CLIENT_NAME}.conf"
cat > "$CLIENT_CONFIG_FILE" <<EOF
# WireGuard Client Configuration: $CLIENT_NAME
# Split-tunnel: Only streaming services route through VPN
# Generated: $(date)
#
# IMPORTANT: Replace <SERVER_PUBLIC_KEY> and <EC2_PUBLIC_IP> with actual values
# Get these from: cat /etc/wireguard/server-info.txt (on server)

[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24
DNS = 3.151.46.11  # SmartDNS for browsers (optional - can use regular DNS too)

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

# Generate QR code if qrencode is available
if command -v qrencode >/dev/null 2>&1; then
    qrencode -t ansiutf8 < "$CLIENT_CONFIG_FILE" > "${CLIENT_CONFIG_FILE}.qr.txt" 2>/dev/null || true
    echo ""
    echo "QR Code saved to: ${CLIENT_CONFIG_FILE}.qr.txt"
fi

echo "✅ Generated WireGuard client config: $CLIENT_CONFIG_FILE"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "CLIENT INFORMATION"
echo "═══════════════════════════════════════════════════════════════"
echo "Client Name:     $CLIENT_NAME"
echo "Client IP:       $CLIENT_IP"
echo "Client Public Key:"
echo "$CLIENT_PUBLIC_KEY"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "NEXT STEPS"
echo "═══════════════════════════════════════════════════════════════"
echo "1. Update $CLIENT_CONFIG_FILE with actual server values:"
echo "   - Replace <SERVER_PUBLIC_KEY> with server public key"
echo "   - Replace <EC2_PUBLIC_IP> with your EC2 public IP"
echo ""
echo "2. Add client to WireGuard server:"
echo "   ssh ubuntu@<EC2_IP>"
echo "   sudo /path/to/add-wireguard-client.sh $CLIENT_NAME $CLIENT_PUBLIC_KEY $CLIENT_IP"
echo ""
echo "3. Import $CLIENT_CONFIG_FILE into WireGuard client app"
echo ""
echo "4. Connect and test streaming apps"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "SPLIT-TUNNELING INFO"
echo "═══════════════════════════════════════════════════════════════"
echo "✅ Streaming apps (Netflix, Disney+, Hulu, etc.) → WireGuard VPN"
echo "✅ Normal traffic (web, email, etc.) → Regular connection"
echo "✅ Browsers → SmartDNS (DNS: 3.151.46.11)"
echo ""
echo "AllowedIPs count: $(echo "$ALLOWED_IPS" | tr ',' '\n' | wc -l) IP ranges"
