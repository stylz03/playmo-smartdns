#!/bin/bash
# Generate WireGuard client configuration with split-tunneling
# Only routes streaming service IPs through VPN

set -e

STREAMING_IPS_FILE="${1:-streaming-ip-ranges.txt}"
CLIENT_NAME="${2:-client1}"
SERVER_PUBLIC_KEY="${3:-}"
SERVER_ENDPOINT="${4:-3.151.46.11:51820}"
CLIENT_PRIVATE_KEY="${5:-}"

if [ ! -f "$STREAMING_IPS_FILE" ]; then
    echo "Error: $STREAMING_IPS_FILE not found"
    echo "Run generate-streaming-ip-ranges.sh first"
    exit 1
fi

# Generate client private key if not provided
if [ -z "$CLIENT_PRIVATE_KEY" ]; then
    if command -v wg >/dev/null 2>&1; then
        CLIENT_PRIVATE_KEY=$(wg genkey)
    else
        echo "Error: WireGuard tools not installed. Cannot generate key."
        echo "Install with: apt-get install wireguard-tools"
        exit 1
    fi
fi

# Generate client public key
if command -v wg >/dev/null 2>&1; then
    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
else
    echo "Error: WireGuard tools not installed. Cannot generate public key."
    exit 1
fi

# Read streaming IP ranges
ALLOWED_IPS=$(cat "$STREAMING_IPS_FILE" | tr '\n' ',' | sed 's/,$//')

# Generate client config
CLIENT_CONFIG_FILE="${CLIENT_NAME}.conf"
cat > "$CLIENT_CONFIG_FILE" <<EOF
# WireGuard Client Configuration: $CLIENT_NAME
# Split-tunnel: Only streaming services route through VPN
# Generated: $(date)

[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.0.0.$(echo "$CLIENT_NAME" | tr -cd '0-9' | head -c 2 || echo "2")/24
DNS = 3.151.46.11  # SmartDNS for browsers

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

echo "✅ Generated WireGuard client config: $CLIENT_CONFIG_FILE"
echo ""
echo "Client Public Key (add this to server):"
echo "$CLIENT_PUBLIC_KEY"
echo ""
echo "Configuration summary:"
echo "  - Client: $CLIENT_NAME"
echo "  - AllowedIPs: $(echo "$ALLOWED_IPS" | tr ',' '\n' | wc -l) streaming IP ranges"
echo "  - Normal traffic: Bypasses VPN"
echo "  - Streaming traffic: Routes through VPN"
echo ""
echo "Next steps:"
echo "1. Add client public key to WireGuard server"
echo "2. Import $CLIENT_CONFIG_FILE into WireGuard client app"
echo "3. Connect and test streaming apps"

