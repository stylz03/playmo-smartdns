# WireGuard Split-Tunneling for Selective Routing

## The Goal

Route **only streaming apps** through WireGuard while keeping **normal traffic** on the regular connection. This gives you:
- ✅ Streaming apps work (Netflix, Disney+, Hulu via WireGuard UDP/QUIC)
- ✅ Normal traffic stays fast (not through VPN)
- ✅ Browsers can use SmartDNS (DNS-based routing)

## How WireGuard Split-Tunneling Works

WireGuard uses the `AllowedIPs` configuration to control which traffic goes through the VPN:

```ini
# All traffic through VPN (default)
AllowedIPs = 0.0.0.0/0, ::/0

# Only specific IP ranges through VPN (split-tunneling)
AllowedIPs = 1.2.3.4/32, 5.6.7.8/32
```

## Implementation Options

### Option 1: IP-Based Split-Tunneling (Recommended) ⭐

**How it works:**
- Maintain a list of streaming service IP ranges (Netflix, Disney+, Hulu, etc.)
- Configure WireGuard client with `AllowedIPs` containing only these IPs
- All other traffic bypasses WireGuard

**Pros:**
- ✅ Only streaming traffic goes through VPN
- ✅ Normal traffic stays on regular connection
- ✅ Works automatically once configured

**Cons:**
- ⚠️ Requires maintaining IP ranges (they change occasionally)
- ⚠️ More complex initial setup

**Example Configuration:**
```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.2/24

[Peer]
PublicKey = <server-public-key>
Endpoint = 3.151.46.11:51820
AllowedIPs = 52.84.0.0/15,  # Netflix
             54.239.0.0/16,  # Netflix
             13.107.42.14/32, # Disney+
             23.185.0.0/16    # Hulu
```

---

### Option 2: Domain-Based Routing (Advanced)

**How it works:**
- Use SmartDNS to resolve streaming domains to WireGuard server IP
- Configure WireGuard to only route traffic to its own IP
- Use policy-based routing on the server

**Pros:**
- ✅ Domain-based (easier to maintain than IPs)
- ✅ Works with SmartDNS

**Cons:**
- ❌ More complex server-side configuration
- ❌ Requires policy-based routing rules
- ❌ May not work well with QUIC/HTTP3

---

### Option 3: Per-App Routing (Device-Dependent)

**How it works:**
- Some VPN clients support per-app routing
- Configure specific apps to use WireGuard
- Other apps use regular connection

**Pros:**
- ✅ Simple for users
- ✅ App-specific control

**Cons:**
- ❌ Not available on all devices/clients
- ❌ iOS: Limited support
- ❌ Android: Varies by client

---

### Option 4: Manual Switch (Simplest)

**How it works:**
- Users manually connect/disconnect WireGuard
- When connected: All traffic through VPN (streaming apps work)
- When disconnected: Use SmartDNS (browsers work)

**Pros:**
- ✅ Simplest to implement
- ✅ No IP range maintenance
- ✅ Full control for users

**Cons:**
- ⚠️ Requires manual switching
- ⚠️ All-or-nothing when connected

---

## Recommended Approach: Hybrid with IP-Based Split-Tunneling

### Architecture

```
┌─────────────────────────────────────────────────┐
│  Client Device                                  │
├─────────────────────────────────────────────────┤
│                                                  │
│  Streaming Apps (Netflix, Disney+, Hulu)         │
│  └─> WireGuard VPN (split-tunnel)              │
│      └─> Only streaming IPs routed              │
│                                                  │
│  Normal Traffic (web, email, etc.)               │
│  └─> Regular connection (bypasses VPN)           │
│                                                  │
│  Browsers                                       │
│  └─> SmartDNS (DNS: 3.151.46.11)                │
│      └─> Streaming domains → EC2 IP              │
│      └─> Normal domains → Regular DNS           │
└─────────────────────────────────────────────────┘
```

### Implementation Steps

1. **Get Streaming Service IP Ranges**
   - Netflix: `52.84.0.0/15`, `54.239.0.0/16`, etc.
   - Disney+: Various IPs
   - Hulu: Various IPs
   - Maintain in a config file

2. **Configure WireGuard Server**
   - Set up WireGuard on EC2
   - Configure routing for streaming IPs
   - Set up client IP management

3. **Generate Client Configs**
   - Include only streaming IP ranges in `AllowedIPs`
   - Users connect WireGuard for apps
   - Normal traffic bypasses VPN

4. **Keep SmartDNS for Browsers**
   - Browsers use DNS: `3.151.46.11`
   - Streaming domains resolve to EC2 IP
   - Traffic goes through Nginx stream proxy

### Benefits

- ✅ **Streaming apps**: Work via WireGuard (UDP/QUIC support)
- ✅ **Normal traffic**: Fast, not through VPN
- ✅ **Browsers**: SmartDNS for geo-unblocking
- ✅ **Best of both worlds**: Selective routing

---

## Alternative: Simplified Hybrid

If IP-based split-tunneling is too complex, use:

1. **SmartDNS for browsers** (current setup)
2. **WireGuard for apps** (all traffic when connected)
3. **Users choose**: DNS for browsing, VPN for apps

This is simpler but less automatic.

---

## Next Steps

I can implement:

1. **WireGuard server setup** with split-tunneling support
2. **Streaming IP range database** (Netflix, Disney+, Hulu, etc.)
3. **Client config generator** that creates split-tunnel configs
4. **Terraform automation** for WireGuard installation
5. **Documentation** for users on how to configure clients

Would you like me to proceed with the **IP-based split-tunneling** approach?

