# Why sniproxy is Better for SmartDNS

## Overview

sniproxy is specifically designed for transparent HTTPS/TLS proxying using Server Name Indication (SNI) inspection, making it ideal for SmartDNS services that need to forward streaming traffic.

## Key Advantages Over Squid

### 1. **SNI-Based Routing (HTTPS Support)**

**Problem with Squid:**
- Squid is primarily an HTTP proxy
- For HTTPS, Squid would need to terminate TLS (act as a man-in-the-middle)
- This requires:
  - Installing custom certificates on client devices
  - Breaking end-to-end encryption
  - Potential security warnings in browsers/apps

**Solution with sniproxy:**
- Inspects SNI field in TLS handshake **without terminating TLS**
- Routes traffic based on domain name from SNI
- Maintains end-to-end encryption (client ↔ streaming service)
- No certificate installation needed

**Example:**
```
Client → EC2 (sniproxy) → Netflix
  [TLS encrypted]    [TLS encrypted]
  
sniproxy reads SNI: "netflix.com"
Routes to: netflix.com (original destination)
TLS connection remains intact
```

### 2. **Transparent Proxying**

**How it works:**
1. Client sets DNS to EC2 IP (e.g., `3.151.46.11`)
2. DNS resolves `netflix.com` → `3.151.46.11` (EC2 IP)
3. Client connects to `3.151.46.11:443` (thinking it's Netflix)
4. sniproxy inspects SNI, sees "netflix.com"
5. sniproxy forwards to actual Netflix servers
6. Client gets Netflix content, but traffic appears to come from US (EC2 location)

**Benefits:**
- ✅ No proxy configuration needed on client
- ✅ Works with apps that don't support proxy settings
- ✅ Transparent to the client (they think they're connecting directly)
- ✅ Streaming apps work without modification

### 3. **Better Streaming App Compatibility**

**Squid Limitations:**
- Many streaming apps (Netflix, Disney+, etc.) don't use system proxy settings
- Apps check location via:
  - IP geolocation (your real IP)
  - GPS (mobile devices)
  - TLS fingerprinting
- Squid's HTTP proxy doesn't help with HTTPS-only apps

**sniproxy Advantages:**
- Works at the network level (DNS + SNI routing)
- Apps connect "directly" to streaming services (via EC2)
- Traffic appears to originate from US (EC2 location)
- No app-level configuration needed

### 4. **Performance & Efficiency**

**sniproxy:**
- Lightweight, purpose-built for SNI proxying
- Low latency (no TLS termination)
- High throughput
- Minimal resource usage

**Squid:**
- General-purpose HTTP proxy with caching
- More overhead for streaming (caching not useful for live streams)
- Higher memory usage
- More complex configuration

### 5. **Architecture Comparison**

#### With Squid (Old Setup):
```
Client Device
    ↓ (DNS: 3.151.46.11)
    ↓ (Resolves to US CDN IPs)
    ↓ (Connects directly to streaming service)
Streaming Service (sees client's real IP - blocked)
```

**Problem:** Streaming service sees client's real IP, blocks access.

#### With sniproxy (New Setup):
```
Client Device
    ↓ (DNS: 3.151.46.11)
    ↓ (Resolves netflix.com → 3.151.46.11)
    ↓ (Connects to 3.151.46.11:443)
EC2 Instance (sniproxy)
    ↓ (Inspects SNI: "netflix.com")
    ↓ (Forwards to actual Netflix servers)
Netflix Servers (sees traffic from US EC2 IP - allowed)
    ↓ (Returns content)
EC2 Instance (sniproxy)
    ↓ (Forwards response)
Client Device (receives content)
```

**Result:** Streaming service sees US IP, allows access.

### 6. **Automatic Domain Management**

**With services.json sync:**
- Add new streaming domain to `services.json`
- GitHub Actions automatically:
  1. Updates DNS zones (resolves to EC2 IP)
  2. Updates sniproxy.conf (adds domain to routing table)
  3. Restarts sniproxy
- No manual configuration needed

**Example workflow:**
```json
// services.json
{
  "netflix.com": true,
  "disneyplus.com": true,
  "newstreaming.com": true  // ← Add this
}
```

After push:
- DNS: `newstreaming.com` → `3.151.46.11`
- sniproxy: Routes `newstreaming.com` traffic
- ✅ Works automatically

### 7. **Security & Privacy**

**sniproxy:**
- ✅ Maintains end-to-end TLS encryption
- ✅ No certificate manipulation
- ✅ No man-in-the-middle concerns
- ✅ Client's connection to streaming service is secure

**Squid (if used for HTTPS):**
- ⚠️ Would require TLS termination
- ⚠️ Certificate installation on clients
- ⚠️ Potential security warnings
- ⚠️ More complex security model

## Real-World Use Case

### Scenario: User in Nigeria wants to watch US Netflix

**With Squid:**
1. User sets DNS to EC2 IP
2. DNS resolves to US CDN IPs
3. User connects directly to Netflix
4. Netflix sees Nigerian IP → **BLOCKED** ❌

**With sniproxy:**
1. User sets DNS to EC2 IP
2. DNS resolves `netflix.com` → EC2 IP (`3.151.46.11`)
3. User's device connects to EC2 (thinking it's Netflix)
4. sniproxy inspects SNI, sees "netflix.com"
5. sniproxy forwards to actual Netflix servers
6. Netflix sees US IP (EC2) → **ALLOWED** ✅
7. User receives Netflix content

## Technical Details

### SNI (Server Name Indification)

SNI is sent in the TLS handshake **before encryption**:
```
Client → Server: "Hello, I want to connect to netflix.com"
Server → Client: "Here's my certificate for netflix.com"
[Encrypted connection established]
```

sniproxy reads the unencrypted SNI field to determine routing, then forwards the entire encrypted connection.

### DNS Resolution Strategy

**Old (Squid):** Resolve to static US CDN IPs
- Problem: CDN IPs change, may not be optimal
- Problem: Direct connection bypasses proxy

**New (sniproxy):** Resolve to EC2 IP
- Solution: All traffic flows through EC2
- Solution: sniproxy handles routing
- Solution: Traffic appears from US location

## Summary

| Feature | Squid | sniproxy |
|---------|-------|----------|
| HTTPS Support | Requires TLS termination | Native SNI inspection |
| Client Config | Proxy settings needed | DNS only |
| App Compatibility | Limited (no proxy support) | Works with all apps |
| Performance | Higher overhead | Lightweight |
| Security | Certificate management | End-to-end encryption |
| Streaming Apps | May not work | Works transparently |
| Setup Complexity | More complex | Simpler |

## Conclusion

sniproxy is the **right tool for the job** because:

1. ✅ **Designed for HTTPS/TLS proxying** (what streaming services use)
2. ✅ **Transparent operation** (no client configuration)
3. ✅ **Better app compatibility** (works with apps that ignore proxy settings)
4. ✅ **Maintains security** (no certificate manipulation)
5. ✅ **Automatic domain management** (sync from services.json)
6. ✅ **Better performance** (lightweight, purpose-built)

This makes sniproxy the industry-standard solution for SmartDNS services, used by commercial providers like SmartDNSProxy, Unlocator, and others.

