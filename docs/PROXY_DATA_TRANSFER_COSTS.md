# Proxy Data Transfer Costs Explained

## How Data Flows Through the Proxy

When a client streams through the proxy:

```
Client Device → EC2 Proxy (Squid) → Streaming Service (Netflix)
                ↓
         (Outbound: CHARGED)
         
Streaming Service → EC2 Proxy → Client Device
                ↓
         (Outbound: CHARGED)
```

## What Gets Charged

### ✅ CHARGED (Outbound from EC2):
- **All streaming content** sent from EC2 to clients
- **All requests** sent from EC2 to streaming services (small)
- **Example**: If client streams 50GB of Netflix, you pay for 50GB outbound

### ❌ FREE (Inbound to EC2):
- Data FROM streaming services TO EC2 (inbound)
- Data FROM clients TO EC2 (inbound)
- **AWS doesn't charge for inbound data transfer**

## Cost Calculation

### Example Scenarios:

**1 Client, 100GB streaming/month:**
- Outbound: 100GB
- First 100GB: **FREE**
- **Cost: $0/month** ✅

**1 Client, 200GB streaming/month:**
- Outbound: 200GB
- First 100GB: FREE
- Next 100GB: 100GB × $0.09 = **$9/month**

**5 Clients, 50GB each (250GB total):**
- Outbound: 250GB
- First 100GB: FREE
- Next 150GB: 150GB × $0.09 = **$13.50/month**

**10 Clients, 100GB each (1TB total):**
- Outbound: 1,000GB
- First 100GB: FREE
- Next 900GB: 900GB × $0.09 = **$81/month**

## Cost Optimization Strategies

### 1. **Limit Proxy Usage** (Recommended)
Only use proxy for streaming domains that actually need geo-unblocking:
- ✅ Netflix, Disney+, Hulu (US-only content)
- ❌ YouTube, general web browsing (no proxy needed)

### 2. **Compression** (Minimal Impact)
Enable compression in Squid for non-video content:
- Helps with web pages, images
- **Doesn't help with video** (already compressed)

### 3. **Caching** (Not Recommended for Streaming)
- Video content is usually not cacheable (DRM, unique URLs)
- Static assets (images, CSS) could be cached
- **Current config disables caching** (correct for streaming)

### 4. **Client-Side Optimization**
- Encourage clients to use lower quality settings when possible
- Monitor usage per client
- Set usage limits/quotas

### 5. **Monitor and Alert**
Set up CloudWatch alarms:
- Alert when approaching 100GB (free tier limit)
- Alert when monthly cost exceeds threshold
- Track per-client usage

## Cost Comparison: With vs Without Proxy

### Without Proxy (DNS Only):
- **Cost**: ~$8-9/month (just EC2)
- **Limitation**: May not work (streaming services check actual IP)

### With Proxy (Current Setup):
- **Low usage (<100GB)**: ~$8-9/month ✅
- **Medium usage (500GB)**: ~$44-45/month
- **High usage (1TB)**: ~$89/month
- **Benefit**: Actually works for geo-unblocking

## Alternative: Client Pays for Data Transfer

You could:
1. **Charge clients** based on usage
2. **Set usage limits** per client
3. **Premium tiers** (unlimited vs limited)
4. **Monitor per-client usage** via API/Firestore

## Real-World Example

**Scenario**: 10 clients, average 50GB streaming/month each = 500GB total

**Costs:**
- EC2: $7-8/month
- Data transfer: 500GB - 100GB free = 400GB × $0.09 = $36/month
- Lambda: $0.20/month
- **Total: ~$44/month**

**If you charge clients $5/month each:**
- Revenue: 10 × $5 = $50/month
- Profit: $50 - $44 = **$6/month** (or break-even)

## Recommendations

1. **Start with current setup** - Monitor actual usage
2. **Set CloudWatch alarms** - Know when costs spike
3. **Track per-client usage** - Identify heavy users
4. **Consider pricing model** - Charge based on usage if needed
5. **Optimize client config** - Only proxy what's necessary

## Bottom Line

**Yes, streaming through proxy counts toward data transfer costs.**

- First 100GB/month: **FREE**
- After that: **$0.09/GB**
- **Main cost driver** for high-usage scenarios

**For low-medium usage (<500GB/month)**: Current setup is cost-effective
**For high usage (1TB+)**: Consider charging clients or using Lightsail with included transfer

