# 📺 How to Set Up SmartDNS on Your TV Box

Simple guide for your customers to set up SmartDNS on Android TV, Fire TV, or Google TV.

## Method 1: WireGuard App (Recommended) ⭐

### Step 1: Install WireGuard App

**Android TV / Google TV:**
1. Open Google Play Store
2. Search "WireGuard"
3. Install "WireGuard" (by WireGuard Development Team)

**Fire TV:**
1. Enable "Apps from Unknown Sources" in settings
2. Download WireGuard APK from: https://www.wireguard.com/install/
3. Install using Downloader app or ADB

### Step 2: Get Your Config

You'll receive from your service provider:
- A `.conf` file, OR
- A QR code image

### Step 3: Import Config

1. Open WireGuard app on your TV
2. Tap the **"+"** button (bottom right)
3. Choose one:
   - **"Import from file"** - Select the `.conf` file
   - **"Scan QR code"** - Scan the QR code (if you have it on another device)

### Step 4: Enable Auto-Connect

1. Tap on your tunnel name (the config you just imported)
2. Enable **"Always-on VPN"** or **"Auto-connect"**
3. Enable **"On-demand connection"** (if available)

### Step 5: Connect

1. Toggle the switch to **ON** (connect)
2. You should see "Connected" status
3. **Done!**

### ✅ Your TV box will now:
- Auto-connect on boot
- Use SmartDNS automatically
- Streaming apps will work!

---

## Method 2: Router DNS (Best for Multiple Devices)

If you have access to your router:

1. **Open router admin panel:**
   - Usually: `192.168.1.1` or `192.168.0.1`
   - Check router manual for IP address

2. **Find DNS settings:**
   - Look for "DNS Settings" or "Internet Settings"
   - May be under "WAN" or "Network" section

3. **Set DNS:**
   - Primary DNS: `3.151.46.11`
   - Secondary DNS: `8.8.8.8` (backup)

4. **Save and restart router**

5. **All devices** on your network will automatically use SmartDNS!

---

## Troubleshooting

### WireGuard Not Auto-Connecting

1. Check "Always-on VPN" is enabled
2. Restart TV box
3. Check WireGuard app has necessary permissions

### Apps Still Not Working

1. Make sure WireGuard is connected (green/active)
2. Try disconnecting and reconnecting
3. Restart TV box

### Need Help?

Contact your service provider for support.

