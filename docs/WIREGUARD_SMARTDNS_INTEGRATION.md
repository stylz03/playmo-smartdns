# WireGuard + SmartDNS Integration

## The Question

If WireGuard routes traffic through VPN, will it use SmartDNS (ControlD)?

## Answer: It Depends on Configuration

### Current Setup

- **SmartDNS**: EC2 (3.151.46.11) → BIND9 → ControlD DNS
- **WireGuard**: Routes traffic through EC2 VPN tunnel

### How They Work Together

**Option 1: WireGuard with SmartDNS DNS (Recommended) ⭐**

Configure WireGuard client to use SmartDNS for DNS resolution:

```ini
[Interface]
DNS = 3.151.46.11  # SmartDNS (EC2)
```

**How it works:**
- Traffic goes through WireGuard VPN tunnel
- DNS queries use SmartDNS (3.151.46.11)
- SmartDNS forwards to ControlD
- ControlD returns geo-unblocked IPs
- ✅ Works!

**Option 2: WireGuard Routes Through EC2 (Current Setup)**

If WireGuard routes traffic through EC2:
- Traffic goes: Client → WireGuard → EC2 → Internet
- EC2 uses ControlD DNS for its own queries
- But client's DNS queries might not use SmartDNS

**Solution:** Set DNS in WireGuard config to `3.151.46.11`

**Option 3: Split-Tunneling (DNS Only)**

Configure WireGuard to only change DNS, not route traffic:
- Set `AllowedIPs = 0.0.0.0/0` but configure to only change DNS
- Traffic uses regular connection
- DNS uses SmartDNS
- ⚠️ May not work reliably on Android TV

## Best Solution for TV Boxes

### Configure WireGuard to Use SmartDNS

Update the TV box config generator to always set DNS:

```ini
[Interface]
DNS = 3.151.46.11  # SmartDNS via ControlD
```

This ensures:
- WireGuard handles VPN connection (auto-connect)
- DNS queries go to SmartDNS (3.151.46.11)
- SmartDNS forwards to ControlD
- ControlD handles geo-unblocking
- ✅ Best of both worlds!

## Updated TV Box Config

The config should look like:

```ini
[Interface]
PrivateKey = ...
Address = 10.0.0.X/24
DNS = 3.151.46.11  # SmartDNS (uses ControlD)

[Peer]
PublicKey = ...
Endpoint = 3.151.46.11:51820
AllowedIPs = 0.0.0.0/0, ::/0  # All traffic through VPN
PersistentKeepalive = 25
```

**Result:**
- Traffic routes through WireGuard VPN
- DNS queries use SmartDNS (3.151.46.11)
- SmartDNS forwards to ControlD
- ControlD returns geo-unblocked IPs
- ✅ Everything works!

## Alternative: DNS-Only VPN App

If you want DNS-only (no traffic routing):

Create or use an app that:
- Uses Android VPN API
- Only changes DNS (doesn't route traffic)
- Auto-connects on boot
- Simple: "Enter DNS" → "Connect"

This would be a custom solution, but simpler for users.

## Recommendation

**For TV Boxes: Use WireGuard with SmartDNS DNS**

1. WireGuard provides auto-connect (like VPN)
2. DNS set to SmartDNS (3.151.46.11)
3. SmartDNS uses ControlD
4. Everything works together!

The key is setting `DNS = 3.151.46.11` in the WireGuard config.

