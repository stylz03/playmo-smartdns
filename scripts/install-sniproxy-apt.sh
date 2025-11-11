#!/bin/bash
# Try to install sniproxy from package (if available) or compile with better error handling

set -e

echo "=========================================="
echo "Installing sniproxy (trying package first)"
echo "=========================================="

# Try to install from package first (may not be available)
if apt-cache search sniproxy 2>/dev/null | grep -q sniproxy; then
    echo "Found sniproxy package, installing..."
    sudo apt-get update
    sudo apt-get install -y sniproxy
    echo "✅ Installed from package"
else
    echo "No package available, compiling from source..."
    echo ""
    
    # Install dependencies
    echo "[1/6] Installing dependencies..."
    sudo apt-get update -y
    sudo apt-get install -y build-essential libev-dev libpcre3-dev autotools-dev automake git
    echo "✅ Dependencies installed"
    
    # Clone
    echo "[2/6] Cloning repository..."
    cd /tmp
    rm -rf sniproxy
    git clone --depth 1 https://github.com/dlundquist/sniproxy.git
    cd sniproxy
    echo "✅ Repository cloned"
    
    # Autogen with timeout
    echo "[3/6] Running autogen.sh..."
    timeout 60 ./autogen.sh || {
        echo "❌ autogen.sh failed or timed out"
        exit 1
    }
    echo "✅ Autogen complete"
    
    # Configure with timeout and output
    echo "[4/6] Running configure (max 2 minutes)..."
    timeout 120 ./configure 2>&1 | tee /tmp/configure.log || {
        echo "❌ Configure failed or timed out"
        echo "Last 20 lines of config.log:"
        tail -20 /tmp/configure.log
        exit 1
    }
    echo "✅ Configure complete"
    
    # Make with timeout and progress
    echo "[5/6] Compiling (max 5 minutes - this is the slow part)..."
    echo "   Start time: $(date)"
    timeout 300 make 2>&1 | tee /tmp/make.log || {
        echo "❌ Compilation failed or timed out"
        echo "Last 30 lines of make.log:"
        tail -30 /tmp/make.log
        exit 1
    }
    echo "   End time: $(date)"
    echo "✅ Compilation complete"
    
    # Install
    echo "[6/6] Installing..."
    sudo make install
    echo "✅ Installation complete"
fi

# Setup service
echo ""
echo "Setting up service..."
sudo useradd -r -s /bin/false sniproxy 2>/dev/null || true
sudo mkdir -p /etc/sniproxy

# Create config
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
echo "✅ Installation complete!"

