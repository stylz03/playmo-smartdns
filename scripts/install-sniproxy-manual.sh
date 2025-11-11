#!/bin/bash
# Manual sniproxy installation script
# Run this on EC2 if sniproxy wasn't installed via user_data

set -e

echo "=========================================="
echo "Installing sniproxy manually"
echo "=========================================="

# Install dependencies
echo "Installing build dependencies..."
sudo apt-get update -y
sudo apt-get install -y build-essential libev-dev libpcre3-dev autotools-dev automake

# Clone and build sniproxy
echo "Cloning sniproxy repository..."
cd /tmp
if [ -d "sniproxy" ]; then
    echo "sniproxy directory exists, removing..."
    rm -rf sniproxy
fi

git clone https://github.com/dlundquist/sniproxy.git
cd sniproxy

echo "Building sniproxy..."
./autogen.sh
./configure
make
sudo make install

# Create sniproxy user if it doesn't exist
if ! id -u sniproxy >/dev/null 2>&1; then
    echo "Creating sniproxy user..."
    sudo useradd -r -s /bin/false sniproxy
fi

# Create sniproxy directory
sudo mkdir -p /etc/sniproxy

# Download sync script
echo "Downloading sync script..."
sudo curl -s -f https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/sync-sniproxy-config.sh -o /usr/local/bin/sync-sniproxy-config.sh
sudo chmod +x /usr/local/bin/sync-sniproxy-config.sh

# Download and sync initial config
echo "Downloading services.json and syncing config..."
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
curl -s -f https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json -o /tmp/services.json

if [ -f /tmp/services.json ]; then
    EC2_IP="$EC2_IP" sudo /usr/local/bin/sync-sniproxy-config.sh /tmp/services.json /etc/sniproxy/sniproxy.conf
else
    echo "Warning: Could not download services.json, creating minimal config..."
    sudo tee /etc/sniproxy/sniproxy.conf > /dev/null <<'EOF'
user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

table {
    .netflix.com
    .disneyplus.com
    .hulu.com
}

listen 0.0.0.0:443 {
    proto tls
    table {
        .netflix.com
        .disneyplus.com
        .hulu.com
    }
}

listen 0.0.0.0:80 {
    proto http
    table {
        .netflix.com
        .disneyplus.com
        .hulu.com
    }
}
EOF
fi

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/sniproxy.service > /dev/null <<'EOF'
[Unit]
Description=SNI Proxy for SmartDNS
After=network.target

[Service]
Type=forking
User=sniproxy
ExecStart=/usr/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
echo "Enabling and starting sniproxy..."
sudo systemctl daemon-reload
sudo systemctl enable sniproxy
sudo systemctl start sniproxy

# Verify installation
echo ""
echo "=========================================="
echo "Verification"
echo "=========================================="
if systemctl is-active --quiet sniproxy; then
    echo "✅ sniproxy is running"
    sudo systemctl status sniproxy --no-pager -l | head -10
else
    echo "❌ sniproxy failed to start"
    sudo systemctl status sniproxy --no-pager -l
    exit 1
fi

echo ""
echo "Checking if sniproxy is listening..."
sudo ss -tulnp | grep sniproxy || echo "⚠️ sniproxy not listening yet (may need a moment)"

echo ""
echo "✅ sniproxy installation complete!"

