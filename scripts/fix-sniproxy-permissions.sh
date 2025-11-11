#!/bin/bash
# Fix sniproxy permissions to bind to privileged ports
# Run: sudo bash fix-sniproxy-permissions.sh

set -e

echo "=========================================="
echo "Fixing sniproxy permissions"
echo "=========================================="

# Stop sniproxy
sudo systemctl stop sniproxy 2>/dev/null || true

# Check if sniproxy binary exists
if [ ! -f /usr/local/sbin/sniproxy ]; then
    echo "❌ sniproxy binary not found at /usr/local/sbin/sniproxy"
    exit 1
fi

# Give sniproxy capability to bind to privileged ports (80, 443)
echo "Setting capabilities for sniproxy binary..."
sudo setcap 'cap_net_bind_service=+ep' /usr/local/sbin/sniproxy

# Verify capabilities
echo ""
echo "Verifying capabilities:"
getcap /usr/local/sbin/sniproxy

# Update systemd service to run as sniproxy user (not root)
echo ""
echo "Checking systemd service configuration..."
if grep -q "User=root" /etc/systemd/system/sniproxy.service 2>/dev/null; then
    echo "⚠️ Service is configured to run as root. Updating to run as sniproxy user..."
    sudo sed -i 's/User=root/User=sniproxy/' /etc/systemd/system/sniproxy.service || true
fi

# Ensure sniproxy user exists
if ! id sniproxy >/dev/null 2>&1; then
    echo "Creating sniproxy user..."
    sudo useradd -r -s /bin/false sniproxy
fi

# Ensure service file has correct user
if ! grep -q "User=sniproxy" /etc/systemd/system/sniproxy.service 2>/dev/null; then
    echo "Updating service file to use sniproxy user..."
    sudo sed -i '/^\[Service\]/aUser=sniproxy' /etc/systemd/system/sniproxy.service
fi

# Restart service
echo ""
echo "Restarting sniproxy service..."
sudo systemctl daemon-reload
sudo systemctl restart sniproxy
sleep 3

# Check status
if sudo systemctl is-active --quiet sniproxy; then
    echo ""
    echo "=========================================="
    echo "✅ SNIPROXY IS RUNNING!"
    echo "=========================================="
    sudo systemctl status sniproxy --no-pager -l | head -20
    echo ""
    echo "Ports in use:"
    sudo ss -tulnp | grep sniproxy || sudo ss -tulnp | grep -E ':80 |:443 '
    echo ""
    echo "Process info:"
    ps aux | grep sniproxy | grep -v grep
else
    echo ""
    echo "=========================================="
    echo "❌ SNIPROXY FAILED TO START"
    echo "=========================================="
    sudo journalctl -xeu sniproxy.service --no-pager | tail -25
    
    # Check if capabilities are set
    echo ""
    echo "Checking capabilities:"
    getcap /usr/local/sbin/sniproxy || echo "⚠️ No capabilities set!"
    
    # Try running as root as fallback
    echo ""
    echo "Trying fallback: running as root..."
    sudo sed -i 's/User=sniproxy/User=root/' /etc/systemd/system/sniproxy.service
    sudo systemctl daemon-reload
    sudo systemctl restart sniproxy
    sleep 3
    
    if sudo systemctl is-active --quiet sniproxy; then
        echo "✅ SNIPROXY IS RUNNING (as root - less secure but functional)!"
        sudo systemctl status sniproxy --no-pager -l | head -15
    else
        echo "❌ Still failing. Please check the logs above."
        exit 1
    fi
fi

