# Current SmartDNS IP Address

## Current Configuration

**Elastic IP:** `3.151.75.152`  
**API URL:** `http://3.151.75.152:5000`  
**Proxy:** `3.151.75.152:3128`  
**DNS Server:** `3.151.75.152`  
**Region:** `us-east-2` (Ohio, USA)

## Previous IP

**Old IP:** `3.151.46.11` (may still exist in AWS as unassociated EIP)

## Client Configuration

### DNS Settings
Set your device DNS to: **3.151.75.152**

### Proxy Settings (for streaming domains)
- **Proxy hostname:** `3.151.75.152`
- **Proxy port:** `3128`

### API Endpoint
- **Base URL:** `http://3.151.75.152:5000`
- **Health check:** `http://3.151.75.152:5000/health`

## Quick Test Commands

```bash
# Test DNS
dig @3.151.75.152 netflix.com +short

# Test API
curl http://3.151.75.152:5000/health

# Register IP
curl -X POST http://3.151.75.152:5000/api/clients/test/ips \
  -H "Content-Type: application/json" \
  -d '{"ip_address": "YOUR_IP", "source": "manual"}'

# Test proxy
curl -x http://3.151.75.152:3128 http://netflix.com
```

## If IP Changes Again

If Terraform recreates the instance and IP changes:

1. **Check GitHub Actions output** for new IP
2. **Update this file** with new IP
3. **Update client configurations**
4. **Check if old EIP exists** in AWS Console (EC2 → Elastic IPs)
5. **Optionally associate old EIP** if you want to keep the same IP

## Preventing IP Changes

The lifecycle rules added to Terraform should help prevent unnecessary recreation. However:

- **user_data changes** may still trigger recreation
- **AMI updates** will trigger recreation
- **Instance type changes** will trigger recreation

To minimize changes:
- Use `terraform plan` before applying
- Update configurations manually when possible
- Use targeted applies for specific resources

