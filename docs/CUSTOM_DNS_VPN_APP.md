# Custom DNS-Only VPN App - Implementation Guide

## Overview

Create a simple Android TV app that:
- Uses Android VPN API
- Only changes DNS (doesn't route traffic)
- Auto-connects on boot
- Simple UI: "Enter DNS" → "Connect"

## Difficulty Assessment

### Complexity: Medium ⚠️

**Why it's medium difficulty:**
- ✅ Android VPN API is well-documented
- ✅ Can use existing VPN service examples
- ⚠️ Requires Android development knowledge
- ⚠️ Need to handle DNS-only routing (tricky)
- ⚠️ Auto-connect on boot requires system permissions
- ⚠️ Testing on actual TV boxes needed

## Implementation Options

### Option A: Modify Existing Open Source App (Easiest) ⭐

**Find an existing DNS changer app:**
- Search GitHub for "Android DNS changer VPN"
- Fork and modify existing code
- Change to use your DNS: `3.151.46.11`
- Add auto-connect feature

**Time estimate:** 1-2 days (if you find good base code)

**Pros:**
- Faster to implement
- Can learn from existing code
- Less code to write

**Cons:**
- Need to understand existing codebase
- May have unwanted features to remove

### Option B: Build from Scratch (More Control)

**Create new Android app:**
- Use Android Studio
- Implement VPNService
- Configure DNS-only routing
- Add auto-connect

**Time estimate:** 3-5 days (for experienced Android developer)

**Pros:**
- Full control
- Custom branding
- Only features you need

**Cons:**
- More time to develop
- Need Android development skills
- More testing required

### Option C: Use Existing App + Customization

**Use apps like:**
- "DNS Changer" (open source)
- "1.1.1.1" (Cloudflare - modify)
- Other DNS changer apps

**Modify to:**
- Pre-configure your DNS
- Add your branding
- Enable auto-connect

**Time estimate:** 2-3 days

## Technical Requirements

### Android VPN API

```java
// Basic VPN service structure
public class SmartDNSService extends VpnService {
    private ParcelFileDescriptor vpnInterface;
    
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Builder builder = new Builder();
        builder.setSession("SmartDNS");
        builder.addAddress("10.0.0.2", 30); // Virtual IP
        builder.addRoute("0.0.0.0", 0); // Route all traffic
        builder.addDnsServer("3.151.46.11"); // Your SmartDNS
        vpnInterface = builder.establish();
        return START_STICKY;
    }
}
```

### DNS-Only Routing (Tricky Part)

**Challenge:** Android VPN API routes ALL traffic by default.

**Solutions:**
1. **Route all traffic, but use SmartDNS for DNS** (easier)
   - Traffic goes through VPN
   - DNS queries use SmartDNS
   - ✅ This is what WireGuard does!

2. **Use routing rules to bypass VPN** (harder)
   - Route only DNS traffic through VPN
   - Other traffic uses regular connection
   - ⚠️ Complex, may not work on all devices

### Auto-Connect on Boot

**Requires:**
- Boot receiver permission
- System-level access (may need device admin)
- Handle device reboots

```java
public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            Intent serviceIntent = new Intent(context, SmartDNSService.class);
            context.startService(serviceIntent);
        }
    }
}
```

## Implementation Steps

### Step 1: Set Up Android Project

1. **Install Android Studio**
2. **Create new project**
   - Target: Android TV / Android 7.0+
   - Minimum SDK: 24 (Android 7.0)

### Step 2: Implement VPN Service

1. **Create VPNService class**
2. **Request VPN permission**
3. **Implement DNS configuration**
4. **Handle connection lifecycle**

### Step 3: Add Auto-Connect

1. **Create BootReceiver**
2. **Request BOOT_COMPLETED permission**
3. **Test on device**

### Step 4: Create Simple UI

1. **Main activity with:**
   - DNS input field (pre-filled: 3.151.46.11)
   - Connect/Disconnect button
   - Status indicator

### Step 5: Build and Test

1. **Build APK**
2. **Test on Android TV**
3. **Test auto-connect on boot**
4. **Fix any issues**

## Estimated Time

**For experienced Android developer:**
- Basic app: 2-3 days
- With auto-connect: 3-4 days
- Testing and polish: 1-2 days
- **Total: 4-6 days**

**For beginner:**
- Learning Android VPN API: 1-2 days
- Implementation: 5-7 days
- Testing: 2-3 days
- **Total: 8-12 days**

## Alternative: Use WireGuard (Recommended)

**Why WireGuard is easier:**
- ✅ Already implemented and tested
- ✅ Works reliably
- ✅ Free and open source
- ✅ Auto-connect works well
- ✅ You already have it set up

**Time to set up:** 30 minutes (generate configs)

## Recommendation

**If you want custom app:**
- **Option A** (modify existing): 1-2 days
- **Option B** (build from scratch): 4-6 days
- **Option C** (use existing + customize): 2-3 days

**If you want fastest solution:**
- **Use WireGuard**: 30 minutes (already done!)

## Next Steps

If you want to proceed with custom app:

1. **Decide on approach:**
   - Modify existing app (fastest)
   - Build from scratch (most control)

2. **Set up development environment:**
   - Android Studio
   - Android TV emulator or device

3. **Start with basic VPN service**
4. **Add DNS configuration**
5. **Add auto-connect**
6. **Test on TV box**

Would you like me to:
- **A)** Help find existing open-source apps to modify?
- **B)** Create a basic Android project structure?
- **C)** Stick with WireGuard (recommended - it's already working)?

