#!/bin/bash
# Add a WireGuard client to the server
# Usage: ./add-wireguard-client.sh <client-name> <client-public-key> [client-ip]

set -e

CLIENT_NAME="${1:-}"
CLIENT_PUBLIC_KEY="${2:-}"
CLIENT_IP="${3:-}"

if [ -z "$CLIENT_NAME" ] || [ -z "$CLIENT_PUBLIC_KEY" ]; then
    echo "Usage: $0 <client-name> <client-public-key> [client-ip]"
    echo "Example: $0 client1 <public-key> 10.0.0.2"
    exit 1
fi

# Generate client IP if not provided
if [ -z "$CLIENT_IP" ]; then
    # Use client number from name (e.g., client1 -> 10.0.0.2, client2 -> 10.0.0.3)
    CLIENT_NUM=$(echo "$CLIENT_NAME" | grep -o '[0-9]\+' | head -1 || echo "2")
    CLIENT_IP="10.0.0.$CLIENT_NUM"
fi

# Check if WireGuard is running
if ! systemctl is-active --quiet wg-quick@wg0; then
    echo "Error: WireGuard is not running. Start it first: systemctl start wg-quick@wg0"
    exit 1
fi

# Add client to WireGuard
echo "Adding client $CLIENT_NAME ($CLIENT_IP) to WireGuard server..."
wg set wg0 peer "$CLIENT_PUBLIC_KEY" allowed-ips "$CLIENT_IP/32"

# Save client info
CLIENT_INFO_FILE="/etc/wireguard/clients/${CLIENT_NAME}.info"
mkdir -p /etc/wireguard/clients
cat > "$CLIENT_INFO_FILE" <<EOF
CLIENT_NAME=$CLIENT_NAME
CLIENT_PUBLIC_KEY=$CLIENT_PUBLIC_KEY
CLIENT_IP=$CLIENT_IP
ADDED_DATE=$(date)
EOF

echo "✅ Client $CLIENT_NAME added successfully"
echo "   IP: $CLIENT_IP"
echo "   Public Key: $CLIENT_PUBLIC_KEY"

# Show current WireGuard status
echo ""
echo "Current WireGuard peers:"
wg show

