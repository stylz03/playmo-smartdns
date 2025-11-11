# WireGuard + SmartDNS Hybrid Setup Guide

## Overview

This guide explains how to set up the hybrid SmartDNS + WireGuard VPN solution for optimal streaming support.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Client Device                                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Browsers                                                │
│  └─> DNS: 3.151.46.11 (SmartDNS)                        │
│      └─> Streaming domains → EC2 IP                     │
│      └─> Traffic flows through Nginx stream proxy       │
│                                                          │
│  Streaming Apps (Netflix, Disney+, Hulu)                 │
│  └─> WireGuard VPN (split-tunnel)                       │
│      └─> Only streaming IPs routed through VPN           │
│      └─> Supports UDP/QUIC/HTTP3                        │
│                                                          │
│  Normal Traffic (web, email, etc.)                       │
│  └─> Regular connection (bypasses VPN)                   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Server Setup (Automatic via Terraform)

The WireGuard server is automatically installed and configured when you deploy via Terraform. The setup includes:

1. **WireGuard server installation** on EC2
2. **IP forwarding enabled** for VPN routing
3. **NAT masquerading** for outbound traffic
4. **Security group** configured for port 51820 UDP

## Client Setup

### Step 1: Generate Streaming IP Ranges

On your local machine or EC2 instance:

```bash
# Download services.json if needed
curl -H "Authorization: token YOUR_GITHUB_TOKEN" \
  https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json \
  -o services.json

# Generate streaming IP ranges
./scripts/generate-streaming-ip-ranges.sh services.json streaming-ip-ranges.txt
```

This creates `streaming-ip-ranges.txt` with CIDR ranges for all streaming services.

### Step 2: Generate Client Configuration

```bash
# Generate client config with split-tunneling
./scripts/generate-wireguard-client-config.sh client1 streaming-ip-ranges.txt
```

This creates `client1.conf` with:
- Client private/public keys
- Server endpoint
- **AllowedIPs** containing only streaming service IPs (split-tunneling)

### Step 3: Get Server Information

SSH into your EC2 instance:

```bash
ssh ubuntu@<EC2_IP>
cat /etc/wireguard/server-info.txt
```

You'll see:
```
SERVER_PUBLIC_KEY=<key>
SERVER_ENDPOINT=<ip>:51820
WIREGUARD_SUBNET=10.0.0.0/24
WIREGUARD_SERVER_IP=10.0.0.1
```

### Step 4: Update Client Config

Edit `client1.conf` and replace:
- `<SERVER_PUBLIC_KEY>` with the actual server public key
- `<EC2_PUBLIC_IP>` with your EC2 public IP

### Step 5: Add Client to Server

On the EC2 instance:

```bash
# The script will show the client public key from Step 2
sudo /usr/local/bin/add-wireguard-client.sh client1 <CLIENT_PUBLIC_KEY> 10.0.0.2
```

### Step 6: Import Client Config

1. **Android/iOS**: Use WireGuard app
   - Import the `.conf` file
   - Or scan QR code if generated

2. **Windows/Mac**: Use WireGuard client
   - Import the `.conf` file

3. **Linux**: Use `wg-quick`
   ```bash
   sudo wg-quick up client1.conf
   ```

### Step 7: Configure DNS (Optional)

For browsers, set DNS to `3.151.46.11` (SmartDNS) for geo-unblocking.

For apps using WireGuard, you can set DNS in the WireGuard config:
```ini
[Interface]
DNS = 3.151.46.11  # SmartDNS
```

## Testing

### Test SmartDNS (Browsers)

1. Set device DNS to `3.151.46.11`
2. Open browser and visit:
   - https://netflix.com
   - https://disneyplus.com
   - https://hulu.com
3. Should see US content

### Test WireGuard (Apps)

1. Connect WireGuard VPN
2. Open streaming apps:
   - Netflix
   - Disney+
   - Hulu
3. Should work (no "not available in your location" error)

### Test Split-Tunneling

1. Connect WireGuard
2. Visit https://whatismyipaddress.com
3. Should show your **regular IP** (not EC2 IP)
4. Open Netflix app
5. Should work (traffic routed through VPN)

## Troubleshooting

### WireGuard Not Connecting

1. Check server status:
   ```bash
   sudo systemctl status wg-quick@wg0
   sudo wg show
   ```

2. Check firewall:
   ```bash
   sudo ufw status
   # Port 51820 UDP should be open
   ```

3. Check security group:
   - AWS Console → EC2 → Security Groups
   - Ensure port 51820 UDP is open from 0.0.0.0/0

### Apps Still Not Working

1. Verify split-tunneling:
   - Check `AllowedIPs` in client config
   - Should contain streaming service IPs

2. Update IP ranges:
   - Streaming services change IPs
   - Re-run `generate-streaming-ip-ranges.sh` periodically

3. Check WireGuard logs:
   ```bash
   sudo journalctl -u wg-quick@wg0 -f
   ```

### Normal Traffic Going Through VPN

If all traffic is going through VPN (not just streaming):

1. Check `AllowedIPs` in client config
2. Should only contain streaming IP ranges
3. Should NOT contain `0.0.0.0/0` or `::/0`

## Maintenance

### Update Streaming IP Ranges

Streaming services change IPs periodically. Update ranges:

```bash
# Re-generate IP ranges
./scripts/generate-streaming-ip-ranges.sh services.json streaming-ip-ranges.txt

# Re-generate client configs
./scripts/generate-wireguard-client-config.sh client1 streaming-ip-ranges.txt

# Update clients (they'll reconnect automatically)
```

### Add New Clients

1. Generate new client config:
   ```bash
   ./scripts/generate-wireguard-client-config.sh client2 streaming-ip-ranges.txt
   ```

2. Add to server:
   ```bash
   sudo /usr/local/bin/add-wireguard-client.sh client2 <PUBLIC_KEY> 10.0.0.3
   ```

### Remove Clients

```bash
sudo wg set wg0 peer <CLIENT_PUBLIC_KEY> remove
```

## Security Notes

1. **Server keys**: Stored in `/etc/wireguard/` (root only)
2. **Client keys**: Keep private keys secure
3. **Security group**: Restrict port 51820 to known IPs if possible
4. **Firewall**: Use UFW or iptables for additional protection

## Benefits of Hybrid Approach

✅ **Browsers**: Fast DNS-based routing (SmartDNS)
✅ **Apps**: Full protocol support (WireGuard UDP/QUIC)
✅ **Normal traffic**: Stays on regular connection (fast)
✅ **Selective routing**: Only streaming traffic through VPN
✅ **Best of both worlds**: Speed + compatibility

