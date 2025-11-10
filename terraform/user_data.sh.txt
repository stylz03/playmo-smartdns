#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get upgrade -y
apt-get install -y bind9 bind9utils bind9-dnsutils unattended-upgrades fail2ban

# Bind9 global options
cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

# Inject selective forward zones
cat > /etc/bind/named.conf.local <<'EOF'
${NAMED_CONF_LOCAL}
EOF

systemctl enable bind9
systemctl restart bind9

# Security hardening
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || true
systemctl restart ssh || true

dpkg-reconfigure -plow unattended-upgrades || true

systemctl enable fail2ban
systemctl start fail2ban
