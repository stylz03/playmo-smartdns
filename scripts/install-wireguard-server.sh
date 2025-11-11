#!/bin/bash
# Install and configure WireGuard VPN server on EC2
# Supports split-tunneling for streaming services only

set -e

echo "=========================================="
echo "Installing WireGuard VPN Server"
echo "=========================================="

# Update system
apt-get update
apt-get install -y wireguard wireguard-tools iptables qrencode

# Enable IP forwarding
echo "Enabling IP forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Create WireGuard directory
mkdir -p /etc/wireguard
cd /etc/wireguard

# Generate server keys if they don't exist
if [ ! -f /etc/wireguard/server_private.key ]; then
    echo "Generating server keys..."
    wg genkey | tee server_private.key | wg pubkey > server_public.key
    chmod 600 server_private.key
    chmod 644 server_public.key
fi

# Get server private and public keys
SERVER_PRIVATE_KEY=$(cat /etc/wireguard/server_private.key)
SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)

echo "✅ Server keys generated"
echo "Server Public Key: $SERVER_PUBLIC_KEY"

# Get EC2 instance private IP (for WireGuard interface)
INSTANCE_PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
WIREGUARD_SUBNET="10.0.0.0/24"
WIREGUARD_SERVER_IP="10.0.0.1"

# Create WireGuard server configuration
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = $WIREGUARD_SERVER_IP/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Clients will be added here dynamically
# Use: wg set wg0 peer <CLIENT_PUBLIC_KEY> allowed-ips <CLIENT_IP>/32
EOF

# Set permissions
chmod 600 /etc/wireguard/wg0.conf

# Enable and start WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Verify WireGuard is running
if systemctl is-active --quiet wg-quick@wg0; then
    echo "✅ WireGuard server is running"
    wg show
else
    echo "❌ WireGuard failed to start"
    systemctl status wg-quick@wg0
    exit 1
fi

# Save server info for client config generation
cat > /etc/wireguard/server-info.txt <<EOF
SERVER_PUBLIC_KEY=$SERVER_PUBLIC_KEY
SERVER_ENDPOINT=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):51820
WIREGUARD_SUBNET=$WIREGUARD_SUBNET
WIREGUARD_SERVER_IP=$WIREGUARD_SERVER_IP
EOF

echo ""
echo "=========================================="
echo "✅ WireGuard Server Installation Complete"
echo "=========================================="
echo ""
echo "Server Public Key: $SERVER_PUBLIC_KEY"
echo "Server Endpoint: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):51820"
echo ""
echo "Next steps:"
echo "1. Generate streaming IP ranges: ./generate-streaming-ip-ranges.sh"
echo "2. Generate client configs: ./generate-wireguard-client-config.sh"
echo "3. Add clients to server: wg set wg0 peer <CLIENT_PUBLIC_KEY> allowed-ips <CLIENT_IP>/32"

