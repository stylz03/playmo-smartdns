# Hybrid SmartDNS + WireGuard Quick Start

## What's Been Set Up

✅ **WireGuard VPN server** - Automatically installed on EC2 via Terraform
✅ **Security group** - Port 51820 UDP opened for WireGuard
✅ **Split-tunneling support** - Only streaming IPs route through VPN
✅ **Client management scripts** - Easy client config generation

## Quick Start (3 Steps)

### Step 1: Deploy Infrastructure

The WireGuard server is automatically installed when you deploy via Terraform:

```bash
# Push to GitHub (triggers GitHub Actions)
git push origin main
```

Or deploy locally:
```bash
cd terraform
terraform apply
```

### Step 2: Generate Client Configuration

After deployment, SSH into EC2 and generate client configs:

```bash
# SSH into EC2
ssh ubuntu@<EC2_IP>

# Get server info
cat /etc/wireguard/server-info.txt

# Download scripts (if not already there)
cd /tmp
curl -H "Authorization: token YOUR_GITHUB_TOKEN" \
  https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/generate-streaming-ip-ranges.sh \
  -o generate-streaming-ip-ranges.sh
chmod +x generate-streaming-ip-ranges.sh

curl -H "Authorization: token YOUR_GITHUB_TOKEN" \
  https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/services.json \
  -o services.json

# Generate streaming IP ranges
./generate-streaming-ip-ranges.sh services.json streaming-ip-ranges.txt

# Generate client config
curl -H "Authorization: token YOUR_GITHUB_TOKEN" \
  https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/generate-wireguard-client-config.sh \
  -o generate-wireguard-client-config.sh
chmod +x generate-wireguard-client-config.sh

./generate-wireguard-client-config.sh client1 streaming-ip-ranges.txt
```

### Step 3: Add Client to Server

```bash
# On EC2, add the client (use public key from Step 2)
sudo /usr/local/bin/add-wireguard-client.sh client1 <CLIENT_PUBLIC_KEY> 10.0.0.2

# Update client1.conf with server info
# Replace <SERVER_PUBLIC_KEY> and <EC2_PUBLIC_IP> from server-info.txt
```

### Step 4: Import and Connect

1. **Download** `client1.conf` from EC2
2. **Import** into WireGuard app (Android/iOS/Windows/Mac)
3. **Connect** WireGuard
4. **Set DNS** to `3.151.46.11` for browsers (optional)

## How It Works

### For Browsers (SmartDNS)
- Set DNS to `3.151.46.11`
- Streaming domains resolve to EC2 IP
- Traffic flows through Nginx stream proxy
- ✅ All streaming sites work

### For Apps (WireGuard)
- Connect WireGuard VPN
- Only streaming service IPs route through VPN
- Normal traffic bypasses VPN
- ✅ Apps work (Netflix, Disney+, Hulu)

### Split-Tunneling
- **Streaming apps** → WireGuard VPN (UDP/QUIC support)
- **Normal traffic** → Regular connection (fast)
- **Browsers** → SmartDNS (DNS-based)

## Testing

### Test SmartDNS
1. Set DNS to `3.151.46.11`
2. Visit https://netflix.com in browser
3. Should see US content ✅

### Test WireGuard
1. Connect WireGuard
2. Open Netflix app
3. Should work (no geo-block) ✅

### Test Split-Tunneling
1. Connect WireGuard
2. Visit https://whatismyipaddress.com
3. Should show your **regular IP** (not EC2 IP) ✅
4. Open Netflix app
5. Should work (traffic through VPN) ✅

## Troubleshooting

### WireGuard Not Connecting
```bash
# Check server status
sudo systemctl status wg-quick@wg0
sudo wg show

# Check firewall
sudo ufw status
```

### Apps Still Not Working
1. Verify split-tunneling (check `AllowedIPs` in client config)
2. Update streaming IP ranges (services change IPs)
3. Check WireGuard logs: `sudo journalctl -u wg-quick@wg0 -f`

## Files Created

- `scripts/install-wireguard-server.sh` - Server installation
- `scripts/add-wireguard-client.sh` - Add clients to server
- `scripts/generate-streaming-ip-ranges.sh` - Generate IP ranges
- `scripts/generate-wireguard-client-config.sh` - Generate client configs
- `docs/WIREGUARD_SETUP_GUIDE.md` - Full setup guide
- `docs/WIREGUARD_SPLIT_TUNNELING.md` - Split-tunneling details

## Next Steps

1. **Deploy** via Terraform (GitHub Actions or local)
2. **Generate** client configs
3. **Test** with browsers and apps
4. **Update** IP ranges periodically (streaming services change IPs)

For detailed instructions, see `docs/WIREGUARD_SETUP_GUIDE.md`.

