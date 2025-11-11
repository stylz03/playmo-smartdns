#!/bin/bash
# Step-by-step sniproxy installation with progress checks
# Run each section separately to see where it might be failing

set -e

echo "=========================================="
echo "Step-by-Step sniproxy Installation"
echo "=========================================="
echo ""

# Step 1: Dependencies
echo "[STEP 1/7] Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y build-essential libev-dev libpcre3-dev autotools-dev automake git
echo "✅ Step 1 complete"
echo ""

# Step 2: Clone
echo "[STEP 2/7] Cloning repository..."
cd /tmp
rm -rf sniproxy
git clone https://github.com/dlundquist/sniproxy.git
echo "✅ Step 2 complete"
echo ""

# Step 3: Autogen
echo "[STEP 3/7] Running autogen.sh..."
cd sniproxy
./autogen.sh
echo "✅ Step 3 complete"
echo ""

# Step 4: Configure
echo "[STEP 4/7] Running configure (this may take 1-2 minutes)..."
timeout 120 ./configure || {
    echo "❌ Configure failed or timed out"
    exit 1
}
echo "✅ Step 4 complete"
echo ""

# Step 5: Make (compile)
echo "[STEP 5/7] Compiling (this takes 2-3 minutes)..."
echo "   Starting compilation at $(date)"
timeout 300 make || {
    echo "❌ Compilation failed or timed out"
    echo "   Check for errors above"
    exit 1
}
echo "✅ Step 5 complete at $(date)"
echo ""

# Step 6: Install
echo "[STEP 6/7] Installing..."
sudo make install
echo "✅ Step 6 complete"
echo ""

# Step 7: Setup service
echo "[STEP 7/7] Setting up service..."
sudo useradd -r -s /bin/false sniproxy 2>/dev/null || true
sudo mkdir -p /etc/sniproxy

# Create minimal config
sudo tee /etc/sniproxy/sniproxy.conf > /dev/null <<'EOF'
user daemon
pidfile /var/run/sniproxy.pid
error_log { syslog daemon priority notice }
table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com }
listen 0.0.0.0:443 { proto tls table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com } }
listen 0.0.0.0:80 { proto http table { .netflix.com .disneyplus.com .hulu.com .nflxvideo.net .bamgrid.com .hbomax.com .max.com .peacocktv.com .paramountplus.com .paramount.com .espn.com .espnplus.com .primevideo.com .amazonvideo.com .tv.apple.com .sling.com .discoveryplus.com .tubi.tv .crackle.com .roku.com .tntdrama.com .tbs.com .flosports.tv .magellantv.com .aetv.com .directv.com .britbox.com .dazn.com .fubo.tv .philo.com .dishanywhere.com .xumo.tv .hgtv.com .amcplus.com .mgmplus.com } }
EOF

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

sudo systemctl daemon-reload
sudo systemctl enable sniproxy
sudo systemctl start sniproxy

echo "✅ Step 7 complete"
echo ""

# Verify
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
echo "✅ Installation complete!"

