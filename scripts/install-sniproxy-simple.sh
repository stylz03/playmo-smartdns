#!/bin/bash
# Simple sniproxy installation script
# Run: sudo bash install-sniproxy-simple.sh

set -e

echo "=========================================="
echo "Installing sniproxy for SmartDNS"
echo "=========================================="

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential libev-dev libpcre3-dev autotools-dev automake git

# Clone and build sniproxy
echo "Cloning sniproxy..."
cd /tmp
rm -rf sniproxy
git clone --depth 1 https://github.com/dlundquist/sniproxy.git
cd sniproxy

echo "Configuring sniproxy..."
timeout 60 ./autogen.sh
timeout 120 ./configure

echo "Compiling sniproxy (this may take a few minutes)..."
timeout 300 make

echo "Installing sniproxy..."
sudo make install

# Create sniproxy user
echo "Creating sniproxy user..."
sudo useradd -r -s /bin/false sniproxy 2>/dev/null || true

# Create directory
sudo mkdir -p /etc/sniproxy

# Create sniproxy.conf
echo "Creating sniproxy configuration..."
sudo tee /etc/sniproxy/sniproxy.conf > /dev/null <<'EOF'
user daemon
pidfile /var/run/sniproxy.pid
error_log { syslog daemon priority notice }
table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com }
listen 0.0.0.0:443 { proto tls table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com } }
listen 0.0.0.0:80 { proto http table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com } }
EOF

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/sniproxy.service > /dev/null <<'EOF'
[Unit]
Description=SNI Proxy for SmartDNS
After=network.target

[Service]
Type=forking
User=sniproxy
ExecStart=/usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf
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

echo ""
echo "=========================================="
echo "✅ sniproxy installation complete!"
echo "=========================================="
sleep 2
sudo systemctl status sniproxy --no-pager -l | head -15

