# SmartDNS Android TV App

Simple DNS-only VPN app for Android TV that auto-connects on boot.

## Features

- ✅ Simple DNS input (pre-filled: 3.151.46.11)
- ✅ One-tap connect/disconnect
- ✅ Auto-connects on boot
- ✅ Works on Android TV, Fire TV, Google TV
- ✅ DNS-only (doesn't route traffic, just changes DNS)

## Development Status

**Status:** Planning/Design Phase

**Estimated Development Time:**
- Modify existing app: 1-2 days
- Build from scratch: 4-6 days

## Implementation Options

### Option 1: Modify Existing App (Recommended)

Find open-source DNS changer app and modify:
- Change default DNS to 3.151.46.11
- Add auto-connect on boot
- Customize branding

### Option 2: Build from Scratch

Create new Android app using:
- Android VPN API
- VPNService class
- BootReceiver for auto-connect
- Simple UI

## Requirements

- Android Studio
- Android SDK 24+ (Android 7.0+)
- Android TV device for testing
- VPN permission

## Next Steps

1. Research existing open-source DNS changer apps
2. Choose implementation approach
3. Set up Android Studio project
4. Implement VPN service
5. Add auto-connect
6. Test on TV box

