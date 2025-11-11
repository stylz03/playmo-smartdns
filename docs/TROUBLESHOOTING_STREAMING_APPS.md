# Troubleshooting Streaming Apps Not Working

If streaming apps (Netflix, Disney+, Hulu) still don't work with WireGuard, here's how to troubleshoot.

## Quick Checks

### 1. Verify WireGuard is Connected

**On your device:**
- Open WireGuard app
- Check that the tunnel shows "Connected" or is toggled ON
- Look for any error messages

### 2. Test Split-Tunneling

**Check your public IP:**
- Visit: https://whatismyipaddress.com
- **Expected:** Your regular IP (not EC2 IP: 3.151.46.11)
- **If shows EC2 IP:** Split-tunneling isn't working - all traffic is going through VPN

### 3. Check AllowedIPs in Config

**On EC2, run:**
```bash
cat /tmp/client1.conf | grep AllowedIPs
```

**Should show:** Many IP ranges (115+), NOT `0.0.0.0/0`

**If shows `0.0.0.0/0`:** All traffic goes through VPN - this is wrong for split-tunneling

## Common Issues

### Issue 1: Split-Tunneling Not Working

**Symptoms:**
- All traffic goes through VPN (IP shows as EC2 IP)
- Normal web browsing is slow

**Fix:**
1. Check WireGuard config on device
2. Verify `AllowedIPs` contains only streaming IP ranges
3. Re-import config if needed

### Issue 2: IP Ranges Incomplete

**Symptoms:**
- Some apps work, others don't
- Apps work sometimes but not always

**Fix:**
Streaming services change IPs frequently. Update IP ranges:

```bash
# On EC2
sudo bash /tmp/setup-client.sh client1
```

This regenerates IP ranges from current DNS lookups.

### Issue 3: Additional Endpoints Not Covered

**Symptoms:**
- App connects but shows "not available in your location"
- Some features work, others don't

**Fix:**
Some apps use additional endpoints not in `services.json`. Add more domains:

```bash
# Edit services.json on EC2 or locally
# Add more subdomains for problematic services
# Then regenerate configs
```

### Issue 4: WireGuard Not Routing Correctly

**Symptoms:**
- WireGuard shows connected
- But apps still don't work

**Fix:**
1. **Check routing on device:**
   - Android: Settings → Network → WireGuard → Check routes
   - iOS: WireGuard app → Check connection status

2. **Verify server is running:**
   ```bash
   ssh ubuntu@3.151.46.11
   sudo wg show
   ```

3. **Check firewall:**
   - Ensure port 51820 UDP is open in AWS security group

## Advanced Troubleshooting

### Test Script

Run this on your device (if possible) or on EC2:

```bash
curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/scripts/test-wireguard-split-tunnel.sh -o /tmp/test-wg.sh
chmod +x /tmp/test-wg.sh
bash /tmp/test-wg.sh
```

### Manual IP Range Update

If specific services aren't working:

1. **Find current IPs:**
   ```bash
   dig +short netflix.com A
   dig +short disneyplus.com A
   ```

2. **Add to AllowedIPs manually** (temporary fix)

3. **Or regenerate configs** with updated ranges

### Check WireGuard Logs

**On device:**
- WireGuard app usually shows connection logs
- Check for errors or connection issues

**On server:**
```bash
sudo journalctl -u wg-quick@wg0 -f
```

## Alternative: Use Full VPN (Not Recommended)

If split-tunneling continues to have issues, you can temporarily use full VPN:

1. **Edit client config:**
   - Change `AllowedIPs` to `0.0.0.0/0, ::/0`
   - This routes ALL traffic through VPN

2. **Re-import config**

3. **Test apps**

**Note:** This makes all traffic go through VPN (slower), but should make all apps work.

## Still Not Working?

1. **Verify WireGuard server is accessible:**
   ```bash
   # From your device, test connection
   ping 3.151.46.11
   ```

2. **Check security group:**
   - AWS Console → EC2 → Security Groups
   - Ensure port 51820 UDP is open from `0.0.0.0/0`

3. **Regenerate everything:**
   ```bash
   # On EC2
   sudo bash /tmp/setup-client.sh client1
   # Download new config
   # Re-import on device
   ```

4. **Check app-specific requirements:**
   - Some apps may require additional configuration
   - Some may detect VPN usage and block

## Expected Behavior

**Working correctly:**
- ✅ Streaming apps (Netflix, Disney+, Hulu) work
- ✅ Normal web traffic uses regular connection (fast)
- ✅ Your IP shows as regular IP (not EC2 IP)
- ✅ Browsers can use SmartDNS (DNS: 3.151.46.11)

**If this isn't happening, follow troubleshooting steps above.**

