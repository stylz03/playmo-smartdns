#!/bin/bash
# Quick sniproxy installation - optimized for speed
# This version checks progress and provides feedback

set -e

echo "=========================================="
echo "Installing sniproxy (this may take 3-5 minutes)"
echo "=========================================="
echo ""

# Install dependencies
echo "[1/6] Installing build dependencies..."
sudo apt-get update -y >/dev/null 2>&1
sudo apt-get install -y build-essential libev-dev libpcre3-dev autotools-dev automake git >/dev/null 2>&1
echo "✅ Dependencies installed"

# Clone and build
echo "[2/6] Cloning sniproxy repository..."
cd /tmp
rm -rf sniproxy
git clone https://github.com/dlundquist/sniproxy.git >/dev/null 2>&1
cd sniproxy
echo "✅ Repository cloned"

echo "[3/6] Configuring build (this may take 1-2 minutes)..."
./autogen.sh >/dev/null 2>&1
./configure >/dev/null 2>&1
echo "✅ Configuration complete"

echo "[4/6] Compiling sniproxy (this may take 2-3 minutes)..."
echo "   (This is normal - compilation takes time on small instances)"
make >/dev/null 2>&1 &
MAKE_PID=$!

# Show progress
while kill -0 $MAKE_PID 2>/dev/null; do
    echo -n "."
    sleep 5
done
wait $MAKE_PID
echo ""
echo "✅ Compilation complete"

echo "[5/6] Installing sniproxy..."
sudo make install >/dev/null 2>&1
echo "✅ Installation complete"

# Create user
echo "[6/6] Setting up service..."
sudo useradd -r -s /bin/false sniproxy 2>/dev/null || true
sudo mkdir -p /etc/sniproxy

# Download sync script with retry
echo "Downloading sync script..."
for i in {1..3}; do
    if sudo curl -s -f --max-time 30 https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/sync-sniproxy-config.sh -o /usr/local/bin/sync-sniproxy-config.sh; then
        break
    fi
    echo "   Retry $i/3..."
    sleep 2
done
sudo chmod +x /usr/local/bin/sync-sniproxy-config.sh 2>/dev/null || true

# Get EC2 IP and download services.json
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Downloading services.json..."
for i in {1..3}; do
    if curl -s -f --max-time 30 https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json -o /tmp/services.json; then
        break
    fi
    echo "   Retry $i/3..."
    sleep 2
done

# Sync config
if [ -f /tmp/services.json ] && [ -f /usr/local/bin/sync-sniproxy-config.sh ]; then
    EC2_IP="$EC2_IP" sudo /usr/local/bin/sync-sniproxy-config.sh /tmp/services.json /etc/sniproxy/sniproxy.conf 2>/dev/null || {
        echo "Creating minimal config..."
        sudo tee /etc/sniproxy/sniproxy.conf > /dev/null <<'EOF'
user daemon
pidfile /var/run/sniproxy.pid
error_log { syslog daemon priority notice }
table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com }
listen 0.0.0.0:443 { proto tls table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com } }
listen 0.0.0.0:80 { proto http table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com } }
EOF
    }
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
echo "=========================================="
echo "Verification"
echo "=========================================="
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

echo ""
echo "✅ sniproxy installation complete!"

