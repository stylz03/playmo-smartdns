# Client Setup Complete! 🎉

Your WireGuard client has been successfully configured with split-tunneling.

## What You Have

- **115 streaming IP ranges** - Only these IPs route through VPN
- **Client config** - Ready to import into WireGuard app
- **Split-tunneling** - Normal traffic bypasses VPN (stays fast)

## Download Config File

From your local machine (Windows/Mac/Linux):

```bash
scp ubuntu@3.151.46.11:/tmp/client1.conf .
```

Or if you're on Windows PowerShell:
```powershell
scp ubuntu@3.151.46.11:/tmp/client1.conf .
```

## Import into WireGuard App

### Android/iOS
1. Open WireGuard app
2. Tap the **+** button
3. Select **"Import from file"** or **"Create from file"**
4. Select `client1.conf`
5. Tap **"Add"**

### Windows/Mac
1. Open WireGuard client
2. Click **"Add tunnel"** or **"Import tunnel"**
3. Select `client1.conf`
4. Click **"Save"**

## Connect and Test

1. **Connect WireGuard** - Toggle the connection in the app
2. **Test streaming apps:**
   - Open Netflix app → Should work! ✅
   - Open Disney+ app → Should work! ✅
   - Open Hulu app → Should work! ✅
3. **Verify split-tunneling:**
   - Visit https://whatismyipaddress.com
   - Should show your **regular IP** (not EC2 IP) ✅
   - This confirms normal traffic bypasses VPN

## For Browsers (Optional)

If you want to use SmartDNS for browsers:

1. **Set DNS to:** `3.151.46.11`
   - Windows: Network Settings → Change adapter options → DNS
   - Android: WiFi settings → Advanced → DNS
   - iOS: Settings → WiFi → (i) → Configure DNS
2. **Test in browser:**
   - Visit https://netflix.com → Should see US content ✅
   - Visit https://disneyplus.com → Should work ✅

## How It Works

### Split-Tunneling Architecture

```
┌─────────────────────────────────────────┐
│  Your Device                             │
├─────────────────────────────────────────┤
│                                          │
│  Streaming Apps (Netflix, Disney+, Hulu)  │
│  └─> WireGuard VPN                       │
│      └─> Only 115 streaming IP ranges    │
│      └─> Routes through EC2 (US-based)   │
│                                          │
│  Normal Traffic (web, email, etc.)      │
│  └─> Regular connection                 │
│      └─> Bypasses VPN (fast!)            │
│                                          │
│  Browsers (optional)                     │
│  └─> SmartDNS (DNS: 3.151.46.11)         │
│      └─> Streaming domains → EC2 IP      │
│      └─> Traffic through Nginx proxy    │
└─────────────────────────────────────────┘
```

## Troubleshooting

### Apps Still Not Working

1. **Check WireGuard connection:**
   - Ensure WireGuard is connected (green/active)
   - Check for any errors in WireGuard app

2. **Verify split-tunneling:**
   - Check `AllowedIPs` in client config
   - Should contain ~115 IP ranges (not `0.0.0.0/0`)

3. **Update IP ranges:**
   - Streaming services change IPs periodically
   - Re-run setup script to update ranges:
     ```bash
     sudo bash /tmp/setup-client.sh client1
     ```

### Normal Traffic Going Through VPN

If all traffic is going through VPN:
- Check `AllowedIPs` in client config
- Should only contain streaming IP ranges
- Should NOT contain `0.0.0.0/0` or `::/0`

### Connection Issues

1. **Check server status:**
   ```bash
   ssh ubuntu@3.151.46.11
   sudo wg show
   ```

2. **Check firewall:**
   - Ensure port 51820 UDP is open in AWS security group
   - Should be open to `0.0.0.0/0`

3. **Check WireGuard logs:**
   ```bash
   sudo journalctl -u wg-quick@wg0 -f
   ```

## Adding More Clients

To add another client:

```bash
sudo bash /tmp/setup-client.sh client2
```

This will:
- Generate new keys for client2
- Assign IP: 10.0.0.2
- Create config: `/tmp/client2.conf`

## Summary

✅ **Streaming apps** → Work via WireGuard (UDP/QUIC support)
✅ **Normal traffic** → Bypasses VPN (stays fast)
✅ **Browsers** → Work via SmartDNS (DNS-based)

You now have a fully functional hybrid SmartDNS + WireGuard setup! 🚀

