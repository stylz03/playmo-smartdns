#!/bin/bash
# Quick sniproxy installation - paste this directly on EC2

set -e

echo "Installing sniproxy..."

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y build-essential libev-dev libpcre3-dev autotools-dev automake git

# Clone and build
cd /tmp
rm -rf sniproxy
git clone https://github.com/dlundquist/sniproxy.git
cd sniproxy
./autogen.sh
./configure
make
sudo make install

# Create user
sudo useradd -r -s /bin/false sniproxy 2>/dev/null || true

# Create directory
sudo mkdir -p /etc/sniproxy

# Download sync script
sudo curl -s -f https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/sync-sniproxy-config.sh -o /usr/local/bin/sync-sniproxy-config.sh || echo "Sync script download failed"
sudo chmod +x /usr/local/bin/sync-sniproxy-config.sh

# Get EC2 IP and download services.json
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
curl -s -f https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json -o /tmp/services.json

# Sync config
if [ -f /tmp/services.json ] && [ -f /usr/local/bin/sync-sniproxy-config.sh ]; then
    EC2_IP="$EC2_IP" sudo /usr/local/bin/sync-sniproxy-config.sh /tmp/services.json /etc/sniproxy/sniproxy.conf
else
    echo "Creating minimal config..."
    sudo tee /etc/sniproxy/sniproxy.conf > /dev/null <<'EOF'
user daemon
pidfile /var/run/sniproxy.pid
error_log { syslog daemon priority notice }
table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com }
listen 0.0.0.0:443 { proto tls table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com } }
listen 0.0.0.0:80 { proto http table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com } }
EOF
fi

# Create service
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

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable sniproxy
sudo systemctl start sniproxy

# Verify
echo ""
if systemctl is-active --quiet sniproxy; then
    echo "✅ sniproxy is running!"
    sudo systemctl status sniproxy --no-pager -l | head -10
else
    echo "❌ sniproxy failed to start"
    sudo systemctl status sniproxy --no-pager -l
    exit 1
fi

echo ""
echo "Checking ports..."
sudo ss -tulnp | grep sniproxy || echo "May need a moment to start listening"

