#!/bin/bash
# Install Nginx with stream_ssl_preread_module for SNI-based proxying
# This replaces sniproxy for better compatibility with modern streaming services
# Run: sudo bash install-nginx-stream.sh

set -e

echo "=========================================="
echo "Installing Nginx with Stream SSL Module"
echo "=========================================="

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y nginx build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libgd-dev libxml2 libxml2-dev uuid-dev

# Stop and remove system Nginx if installed
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "Stopping system Nginx..."
    systemctl stop nginx
fi

# Remove conflicting module configs
if [ -d /etc/nginx/modules-enabled ]; then
    echo "Removing conflicting module configs..."
    rm -f /etc/nginx/modules-enabled/*.conf 2>/dev/null || true
fi

# Download and compile Nginx with stream_ssl_preread_module
echo "Downloading Nginx source..."
cd /tmp
NGINX_VERSION="1.24.0"
if [ ! -f "nginx-${NGINX_VERSION}.tar.gz" ]; then
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
fi

if [ -d "nginx-${NGINX_VERSION}" ]; then
    rm -rf nginx-${NGINX_VERSION}
fi

tar -xf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}/

echo "Configuring Nginx with stream_ssl_preread_module..."
./configure \
    --prefix=/usr/share/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --with-pcre \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/var/run/nginx.pid \
    --with-http_ssl_module \
    --with-http_image_filter_module=dynamic \
    --modules-path=/etc/nginx/modules \
    --with-http_v2_module \
    --with-stream=dynamic \
    --with-http_addition_module \
    --with-http_mp4_module \
    --with-stream_ssl_preread_module \
    --with-stream_ssl_module

echo "Compiling Nginx (this may take a few minutes)..."
make -j$(nproc)

echo "Installing Nginx..."
make install

# Hold nginx packages to prevent auto-updates
apt-mark hold nginx* libnginx* 2>/dev/null || true

# Ensure modules directory exists
mkdir -p /etc/nginx/modules

echo "✅ Nginx installed with stream_ssl_preread_module"

# Tune systemd service for better performance
echo "Tuning Nginx systemd service..."
if [ -f /lib/systemd/system/nginx.service ]; then
    if ! grep -q "LimitNOFILE" /lib/systemd/system/nginx.service; then
        sed -i '/\[Service\]/a LimitNOFILE=65536' /lib/systemd/system/nginx.service
    fi
elif [ -f /etc/systemd/system/nginx.service ]; then
    if ! grep -q "LimitNOFILE" /etc/systemd/system/nginx.service; then
        sed -i '/\[Service\]/a LimitNOFILE=65536' /etc/systemd/system/nginx.service
    fi
fi

# Increase file descriptor limit
ulimit -n 65536

# Tune kernel parameters (optional but recommended)
if ! grep -q "fs.file-max" /etc/sysctl.conf; then
    cat >> /etc/sysctl.conf <<'EOF'

# Nginx tuning for high performance
fs.file-max = 65536
net.core.wmem_default = 37500000
net.core.wmem_max = 75000000
net.core.rmem_default = 37500000
net.core.rmem_max = 75000000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_window_scaling = 2
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
EOF
    sysctl -p
fi

systemctl daemon-reload

echo ""
echo "=========================================="
echo "✅ Nginx installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Run sync-nginx-stream-config.sh to generate Nginx stream config"
echo "2. Restart Nginx: sudo systemctl restart nginx"
echo ""

