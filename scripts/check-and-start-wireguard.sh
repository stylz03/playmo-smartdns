#!/bin/bash
# Check WireGuard status and install/start if needed

set -e

echo "=========================================="
echo "Checking WireGuard Server Status"
echo "=========================================="

# Check if WireGuard is installed
if ! command -v wg >/dev/null 2>&1; then
    echo "❌ WireGuard is not installed"
    echo "Installing WireGuard server..."
    curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/install-wireguard-server.sh -o /tmp/install-wg.sh
    chmod +x /tmp/install-wg.sh
    sudo bash /tmp/install-wg.sh
    exit 0
fi

# Check if WireGuard service exists
if ! systemctl list-unit-files | grep -q wg-quick@wg0; then
    echo "❌ WireGuard service not configured"
    echo "Installing WireGuard server..."
    curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/install-wireguard-server.sh -o /tmp/install-wg.sh
    chmod +x /tmp/install-wg.sh
    sudo bash /tmp/install-wg.sh
    exit 0
fi

# Check if WireGuard is running
if ! systemctl is-active --quiet wg-quick@wg0; then
    echo "⚠️  WireGuard is installed but not running"
    echo "Starting WireGuard server..."
    sudo systemctl start wg-quick@wg0
    sleep 2
    
    if systemctl is-active --quiet wg-quick@wg0; then
        echo "✅ WireGuard server started successfully"
    else
        echo "❌ Failed to start WireGuard"
        echo "Checking status..."
        sudo systemctl status wg-quick@wg0 --no-pager
        exit 1
    fi
else
    echo "✅ WireGuard server is already running"
fi

# Show status
echo ""
echo "=========================================="
echo "WireGuard Server Status"
echo "=========================================="
sudo systemctl status wg-quick@wg0 --no-pager | head -15
echo ""
sudo wg show
echo ""

# Show server info if available
if [ -f /etc/wireguard/server-info.txt ]; then
    echo "=========================================="
    echo "Server Information"
    echo "=========================================="
    cat /etc/wireguard/server-info.txt
    echo ""
fi

echo "✅ WireGuard server is ready!"

