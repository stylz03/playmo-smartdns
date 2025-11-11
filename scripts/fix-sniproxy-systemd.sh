#!/bin/bash
# Fix sniproxy systemd service configuration
# Run: sudo bash fix-sniproxy-systemd.sh

set -e

echo "=========================================="
echo "Fixing Sniproxy Systemd Service"
echo "==========================================

# Stop sniproxy
systemctl stop sniproxy 2>/dev/null || true

# Check current service file
echo "Current service file:"
cat /etc/systemd/system/sniproxy.service

# The issue: sniproxy might need Type=simple instead of Type=forking
# Or it might need to run in foreground mode

# Create corrected service file
cat > /etc/systemd/system/sniproxy.service <<'EOF'
[Unit]
Description=SNI Proxy for SmartDNS
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "✅ Service file updated (Type=simple, foreground mode)"

# Reload and restart
echo ""
echo "Reloading systemd and restarting sniproxy..."
systemctl daemon-reload
systemctl restart sniproxy
sleep 4

if systemctl is-active --quiet sniproxy; then
    echo ""
    echo "=========================================="
    echo "✅ SNIPROXY IS RUNNING!"
    echo "=========================================="
    systemctl status sniproxy --no-pager -l | head -20
    echo ""
    echo "Ports:"
    ss -tulnp | grep sniproxy || ss -tulnp | grep -E ':80 |:443 '
else
    echo ""
    echo "=========================================="
    echo "❌ SNIPROXY STILL FAILED"
    echo "=========================================="
    journalctl -xeu sniproxy.service --no-pager | tail -30
    echo ""
    echo "Trying with Type=forking (original)..."
    # Try forking mode
    sed -i 's/Type=simple/Type=forking/' /etc/systemd/system/sniproxy.service
    sed -i 's/-f//' /etc/systemd/system/sniproxy.service  # Remove -f flag for forking
    systemctl daemon-reload
    systemctl restart sniproxy
    sleep 4
    
    if systemctl is-active --quiet sniproxy; then
        echo "✅ Sniproxy works with Type=forking (no -f flag)"
        systemctl status sniproxy --no-pager -l | head -15
    else
        echo "❌ Both modes failed"
        exit 1
    fi
fi

