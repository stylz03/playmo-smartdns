# TV Box Setup Guide - SmartDNS

Easy guide for users to set up SmartDNS on TV boxes (Android TV, Fire TV, Google TV).

## Option 1: WireGuard App (Recommended) ⭐

### Why WireGuard?
- ✅ Auto-connects on boot (like a VPN)
- ✅ Works on all TV platforms
- ✅ Reliable and stable
- ✅ Can use SmartDNS (DNS: 3.151.46.11)

### Setup Steps for Users

1. **Install WireGuard App**
   - Android TV: Google Play Store → Search "WireGuard"
   - Fire TV: Download APK from wireguard.com
   - Google TV: Google Play Store

2. **Get Your Config**
   - You (admin) generate config for each TV box
   - Share config file or QR code with user

3. **Import Config**
   - Open WireGuard app
   - Tap "+" → "Create from file" or "Scan QR code"
   - Select config file or scan QR code

4. **Enable Auto-Connect**
   - Tap on the tunnel name
   - Enable "Always-on VPN" or "Auto-connect"
   - Enable "On-demand connection" (if available)

5. **Connect**
   - Toggle the switch to connect
   - Should show "Connected"

6. **Done!**
   - TV box will auto-connect on boot
   - SmartDNS will work automatically
   - Streaming apps should work

### For Admin: Generate TV Box Config

```bash
# On EC2
curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/generate-tvbox-wireguard-config.sh -o /tmp/gen-tvbox.sh
chmod +x /tmp/gen-tvbox.sh
sudo bash /tmp/gen-tvbox.sh tvbox1 dns-only
```

This creates:
- `/tmp/tvbox1.conf` - Config file
- `/tmp/tvbox1.png` - QR code (if available)

Share with user via:
- Email
- Download link
- QR code image

## Option 2: DNS Changer App

### Apps to Try:
- **DNS Changer Pro** (Android TV)
- **DNS Changer** (various apps)
- **Smart DNS Proxy** (if compatible)

### Setup:
1. Install DNS changer app
2. Enter DNS: `3.151.46.11`
3. Enable auto-start (if available)
4. Connect

**Note:** May not auto-connect reliably on all devices.

## Option 3: Router-Level DNS (Best for Multiple Devices)

If user has router access:

1. **Access router admin panel**
   - Usually: `192.168.1.1` or `192.168.0.1`
   - Check router manual for IP

2. **Find DNS settings**
   - Look for "DNS Settings" or "Internet Settings"
   - May be under "WAN" or "Internet" section

3. **Set DNS servers:**
   - Primary DNS: `3.151.46.11`
   - Secondary DNS: `8.8.8.8` (Google, as backup)

4. **Save and restart router**

5. **All devices on network** will automatically use SmartDNS!

**Benefits:**
- Works for all devices (TV, phone, tablet, etc.)
- No app needed per device
- Most reliable

## Option 4: Custom DNS VPN App (Advanced)

If you want to create a custom app:

**Features:**
- Simple UI: "Enter DNS" → "Connect"
- Uses Android VPN API
- Only changes DNS (no traffic routing)
- Auto-connects on boot

**Implementation:**
- Android Studio project
- VPNService API
- Simple DNS input UI
- Boot receiver for auto-connect

## Comparison

| Solution | Auto-Connect | Reliability | Ease of Use | Best For |
|----------|--------------|-------------|-------------|----------|
| WireGuard | ✅ Excellent | ✅ Excellent | ⭐⭐⭐ Good | All TV boxes |
| DNS Changer | ⚠️ Varies | ⚠️ Varies | ⭐⭐⭐⭐ Easy | Simple setup |
| Router DNS | ✅ Excellent | ✅ Excellent | ⭐⭐⭐⭐ Easy | Multiple devices |
| Custom App | ✅ Excellent | ✅ Excellent | ⭐⭐⭐⭐ Easy | Branded solution |

## Recommended: WireGuard

Since you already have WireGuard set up, this is the easiest:

1. **Generate TV box configs** (one per TV box)
2. **Share configs with users** (file or QR code)
3. **Users install WireGuard app** (free, available everywhere)
4. **Import config and enable auto-connect**
5. **Done!**

## User Instructions Template

Create a simple guide for users:

```
📺 How to Set Up SmartDNS on Your TV Box

1. Install WireGuard App
   - Open Play Store on your TV
   - Search "WireGuard"
   - Install

2. Import Your Config
   - Open WireGuard app
   - Tap "+" button
   - Select "Import from file" or "Scan QR code"
   - Use the config file/QR code we provided

3. Enable Auto-Connect
   - Tap on your tunnel name
   - Enable "Always-on VPN"
   - Enable "Auto-connect"

4. Connect
   - Toggle the switch to connect
   - You're done!

Your TV box will now auto-connect on boot and SmartDNS will work automatically.
```

## Next Steps

1. **Generate TV box configs** for your users
2. **Create user-friendly setup guide**
3. **Test on actual TV box** to verify auto-connect works
4. **Provide support** for users who need help

Would you like me to create a user-friendly setup guide or help generate TV box configs?

