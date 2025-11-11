#!/bin/bash
# Get WireGuard server information from EC2
# Run this on the EC2 instance

set -e

echo "=========================================="
echo "WireGuard Server Information"
echo "=========================================="

if [ -f /etc/wireguard/server-info.txt ]; then
    echo ""
    cat /etc/wireguard/server-info.txt
    echo ""
    echo "=========================================="
    echo "Current WireGuard Status"
    echo "=========================================="
    sudo wg show
    echo ""
    echo "=========================================="
    echo "Server Public Key (for client configs):"
    echo "=========================================="
    cat /etc/wireguard/server_public.key
    echo ""
else
    echo "❌ WireGuard server not configured yet."
    echo "Run: sudo bash /path/to/install-wireguard-server.sh"
    exit 1
fi

