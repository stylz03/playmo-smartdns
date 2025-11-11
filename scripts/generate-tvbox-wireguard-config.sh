#!/bin/bash
# Generate WireGuard config for TV box with auto-connect settings
# Usage: ./generate-tvbox-wireguard-config.sh <tvbox-name> [dns-only|full-vpn]

set -e

TVBOX_NAME="${1:-tvbox1}"
MODE="${2:-dns-only}"

if [ -z "$TVBOX_NAME" ]; then
    echo "Usage: $0 <tvbox-name> [dns-only|full-vpn]"
    echo "Example: $0 tvbox1 dns-only"
    exit 1
fi

echo "=========================================="
echo "Generating WireGuard Config for TV Box"
echo "=========================================="
echo ""
echo "TV Box Name: $TVBOX_NAME"
echo "Mode: $MODE"
echo ""

# Check if WireGuard server is running
if ! systemctl is-active --quiet wg-quick@wg0; then
    echo "❌ WireGuard server is not running"
    exit 1
fi

# Get server info
if [ ! -f /etc/wireguard/server-info.txt ]; then
    echo "❌ Server info not found"
    exit 1
fi

source /etc/wireguard/server-info.txt

# Generate client keys
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# Get client IP
CLIENT_NUM=$(echo "$TVBOX_NAME" | grep -o '[0-9]\+' | head -1 || echo "10")
CLIENT_IP="10.0.0.$CLIENT_NUM"

# Determine AllowedIPs based on mode
if [ "$MODE" = "dns-only" ]; then
    # DNS-only: Route all traffic through VPN (for DNS), but can use split-tunneling
    # For TV boxes, we'll route all traffic to ensure DNS works
    ALLOWED_IPS="0.0.0.0/0, ::/0"
    echo "Mode: DNS-only (all traffic through VPN for DNS resolution)"
else
    # Full VPN: Route all traffic
    ALLOWED_IPS="0.0.0.0/0, ::/0"
    echo "Mode: Full VPN (all traffic through VPN)"
fi

# Generate config
CONFIG_FILE="/tmp/${TVBOX_NAME}.conf"
cat > "$CONFIG_FILE" <<EOF
# WireGuard Config for TV Box: $TVBOX_NAME
# Mode: $MODE
# Generated: $(date)
# 
# Instructions for TV Box:
# 1. Install WireGuard app on Android TV/Fire TV
# 2. Import this config file
# 3. Enable "Always-on VPN" or "Auto-connect"
# 4. Connect
#
# IMPORTANT: DNS is set to SmartDNS (3.151.46.11)
# SmartDNS forwards to ControlD for geo-unblocking
# So even though traffic goes through WireGuard VPN,
# DNS queries use SmartDNS → ControlD → Geo-unblocked IPs

[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24
DNS = 3.151.46.11  # SmartDNS (EC2) → ControlD → Geo-unblocked IPs

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

# Add client to WireGuard server
echo ""
echo "Adding client to WireGuard server..."
sudo wg set wg0 peer "$CLIENT_PUBLIC_KEY" allowed-ips "$CLIENT_IP/32"

# Save client info
mkdir -p /etc/wireguard/clients
cat > "/etc/wireguard/clients/${TVBOX_NAME}.info" <<EOF
CLIENT_NAME=$TVBOX_NAME
CLIENT_PUBLIC_KEY=$CLIENT_PUBLIC_KEY
CLIENT_IP=$CLIENT_IP
MODE=$MODE
ADDED_DATE=$(date)
EOF

# Generate QR code if available
if command -v qrencode >/dev/null 2>&1; then
    QR_FILE="/tmp/${TVBOX_NAME}.png"
    qrencode -t PNG -o "$QR_FILE" < "$CONFIG_FILE"
    echo "✅ QR code generated: $QR_FILE"
fi

echo ""
echo "=========================================="
echo "✅ TV Box Config Generated!"
echo "=========================================="
echo ""
echo "Config File: $CONFIG_FILE"
echo "Client IP: $CLIENT_IP"
echo "Public Key: $CLIENT_PUBLIC_KEY"
echo ""
echo "For TV Box Users:"
echo "1. Download WireGuard app on Android TV/Fire TV"
echo "2. Import config: $CONFIG_FILE"
echo "   - Or scan QR code: $QR_FILE (if generated)"
echo "3. Enable 'Always-on VPN' or 'Auto-connect'"
echo "4. Connect"
echo ""
echo "Config will auto-connect on boot!"
echo ""

