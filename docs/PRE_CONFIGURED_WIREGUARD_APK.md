# Pre-Configured WireGuard APK for Android TV

## Overview

Create a custom WireGuard APK with your SmartDNS config pre-loaded, so customers just install and connect - no tech knowledge needed!

## Options

### Option 1: Custom WireGuard Fork (Advanced) ⚠️

**Difficulty:** High (requires Android development)
**Time:** 1-2 weeks

**Steps:**
1. Fork WireGuard Android source code
2. Embed default config in app
3. Auto-import config on first launch
4. Build custom APK
5. Sideload to TV boxes

**Pros:**
- Full control
- Custom branding
- Professional solution

**Cons:**
- Requires Android development skills
- Need to maintain fork
- Time-consuming

### Option 2: Wrapper App (Recommended) ⭐

**Difficulty:** Medium (easier than full fork)
**Time:** 2-3 days

**How it works:**
- Create simple Android app
- Bundle WireGuard config file
- Auto-import config on launch
- Enable auto-connect
- One-tap connect

**Pros:**
- Faster to develop
- Easier to maintain
- Can use official WireGuard app
- Just wraps it with auto-setup

**Cons:**
- Requires WireGuard app to be installed
- Or bundle WireGuard library

### Option 3: Config Auto-Import Script (Simplest) ⭐⭐

**Difficulty:** Low
**Time:** 1 day

**How it works:**
- Create simple Android app
- Bundle config file in assets
- On launch, copy config to WireGuard folder
- Show instructions to import

**Pros:**
- Very simple
- Fast to build
- Works with existing WireGuard app

**Cons:**
- Still requires user to tap "Import" once
- Not fully automated

## Recommended: Option 2 (Wrapper App)

### Implementation Plan

**Step 1: Create Android App Structure**

```
SmartDNS-TV/
├── app/
│   ├── src/main/
│   │   ├── java/com/playmo/smartdns/
│   │   │   ├── MainActivity.kt
│   │   │   └── ConfigManager.kt
│   │   ├── res/
│   │   │   ├── layout/
│   │   │   │   └── activity_main.xml
│   │   │   └── raw/
│   │   │       └── default_config.conf
│   │   └── AndroidManifest.xml
│   └── build.gradle
└── build.gradle
```

**Step 2: Bundle Config File**

Place your WireGuard config in `app/src/main/res/raw/default_config.conf`:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.0.X/24
DNS = 3.151.46.11

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = 3.151.46.11:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

**Step 3: Auto-Import Logic**

```kotlin
// Copy config from assets to WireGuard folder
val configFile = File(context.getExternalFilesDir(null), "wg0.conf")
assets.open("raw/default_config.conf").use { input ->
    configFile.outputStream().use { output ->
        input.copyTo(output)
    }
}

// Trigger WireGuard to import
val intent = Intent("com.wireguard.android.action.SET_TUNNEL_UP")
intent.putExtra("tunnel", "wg0")
context.sendBroadcast(intent)
```

**Step 4: Enable Auto-Connect**

```kotlin
// Set as always-on VPN
val vpnManager = VpnManager.getInstance(context)
vpnManager.setAlwaysOn(true)
vpnManager.setBlocking(false)
```

## Alternative: Pre-Built APK with Config

### Generate Config on EC2

1. **Generate config for each customer:**
```bash
./scripts/generate-tvbox-wireguard-config.sh customer1
```

2. **Download config:**
```bash
# From EC2
cat /tmp/customer1.conf
```

3. **Bundle in APK:**
- Place config in app assets
- App auto-imports on first launch

## Simplest Solution: Config File Distribution

Instead of custom APK, distribute pre-configured `.conf` files:

1. **Generate configs on EC2:**
```bash
./scripts/generate-tvbox-wireguard-config.sh customer1
```

2. **Download and share:**
- Download `.conf` file
- Share via email/WhatsApp/QR code
- Customer installs WireGuard app
- Imports config (one tap)
- Enables auto-connect

**This is the easiest for now!**

## Next Steps

**If you want custom APK:**
1. Set up Android Studio
2. Create wrapper app project
3. Bundle config file
4. Implement auto-import
5. Build APK
6. Test on TV box

**If you want simplest solution:**
1. Generate configs on EC2
2. Share config files with customers
3. Provide simple instructions
4. Done!

## Recommendation

**For now:** Use config file distribution (simplest)
- Generate configs on EC2
- Share via QR code or file
- One-tap import in WireGuard app
- Enable auto-connect

**Later:** Build custom APK if you want:
- Custom branding
- Fully automated setup
- No user interaction needed

