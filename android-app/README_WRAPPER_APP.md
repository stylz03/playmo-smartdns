# SmartDNS TV Box Wrapper App

Simple Android app that auto-imports WireGuard config for non-tech-savvy customers.

## Concept

Instead of customers manually importing WireGuard configs, this app:
1. Bundles the WireGuard config file
2. Auto-imports it on first launch
3. Enables auto-connect
4. One-tap connect

## Architecture

### Option A: Use WireGuard Library (Recommended)

Embed WireGuard Android library (`com.wireguard.android:tunnel`) and create a simple wrapper:

```kotlin
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Load bundled config
        val config = loadBundledConfig()
        
        // Import to WireGuard
        importConfig(config)
        
        // Enable auto-connect
        enableAutoConnect()
        
        // Connect
        connect()
    }
}
```

### Option B: Use WireGuard Intent API

If WireGuard app is installed, use intents to import config:

```kotlin
val intent = Intent(Intent.ACTION_VIEW).apply {
    setDataAndType(Uri.fromFile(configFile), "application/x-wireguard-config")
    putExtra("com.wireguard.android.action.IMPORT_CONFIG", true)
}
startActivity(intent)
```

### Option C: Copy Config + Instructions

Simplest approach:
1. Copy config to WireGuard folder
2. Show instructions to user
3. User taps "Import" once

## Implementation Steps

### Step 1: Set Up Project

```bash
# Create Android Studio project
# Target: Android TV / Android 7.0+
# Minimum SDK: 24
```

### Step 2: Add Dependencies

```gradle
dependencies {
    implementation 'com.wireguard.android:tunnel:1.0.0'
    // Or use WireGuard intent API
}
```

### Step 3: Bundle Config

Place config in `app/src/main/res/raw/default_config.conf`

### Step 4: Implement Auto-Import

```kotlin
fun importConfig() {
    val config = resources.openRawResource(R.raw.default_config)
    val configFile = File(getExternalFilesDir(null), "wg0.conf")
    config.copyTo(configFile.outputStream())
    
    // Trigger WireGuard import
    val intent = Intent("com.wireguard.android.action.IMPORT_CONFIG")
    intent.putExtra("config_file", configFile.absolutePath)
    startActivity(intent)
}
```

### Step 5: Enable Auto-Connect

```kotlin
fun enableAutoConnect() {
    val prefs = getSharedPreferences("wireguard", MODE_PRIVATE)
    prefs.edit()
        .putBoolean("auto_connect", true)
        .putBoolean("always_on", true)
        .apply()
}
```

## UI Design

Simple one-screen app:

```
┌─────────────────────────┐
│   SmartDNS TV Box       │
│                         │
│   [Connect Button]      │
│                         │
│   Status: Disconnected  │
│                         │
│   Auto-connect: ON      │
└─────────────────────────┘
```

## Build and Distribution

1. **Build APK:**
```bash
./gradlew assembleRelease
```

2. **Sign APK:**
```bash
jarsigner -keystore keystore.jks app-release.apk smartdns
```

3. **Distribute:**
- Upload to your website
- Share download link
- Customers sideload to TV box

## Alternative: Pre-Configured Config Files

**Simpler approach for now:**

1. Generate configs on EC2
2. Share config files (QR code or download)
3. Customer installs WireGuard app
4. Imports config (one tap)
5. Enables auto-connect

**This works immediately, no app development needed!**

## Next Steps

**If building wrapper app:**
1. Set up Android Studio
2. Create project
3. Implement auto-import
4. Test on TV box
5. Build and distribute

**If using config files (recommended for now):**
1. Use `generate-bulk-tvbox-configs.sh`
2. Share configs with customers
3. Provide simple instructions
4. Done!

