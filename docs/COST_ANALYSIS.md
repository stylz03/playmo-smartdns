# Cost Analysis for Playmo SmartDNS

## Current Setup Costs

### Monthly AWS Costs (Estimated)

1. **EC2 Instance** (us-east-2, Ohio)
   - `t3.micro`: ~$7-8/month (1 vCPU, 1GB RAM) - **Current default**
   - `t3.small`: ~$15/month (2 vCPU, 2GB RAM)
   - `t3.medium`: ~$30/month (2 vCPU, 4GB RAM)
   - **Note**: First 750 hours/month free with AWS Free Tier (new accounts)

2. **Elastic IP**: **FREE** (as long as attached to running instance)

3. **Lambda Function**: **~$0.20/month** (very cheap, pay per request)

4. **Data Transfer** (This is the variable cost):
   - **First 100GB/month**: FREE (outbound from EC2)
   - **100GB-10TB**: $0.09/GB
   - **Example**: 500GB/month = ~$36/month
   - **Example**: 1TB/month = ~$81/month

5. **Storage (EBS)**: ~$1/month for 8GB gp3 volume

### Total Estimated Monthly Cost

**Low usage (100GB data transfer):**
- EC2 t3.micro: $7-8
- Lambda: $0.20
- Storage: $1
- **Total: ~$8-9/month**

**Medium usage (500GB data transfer):**
- EC2 t3.micro: $7-8
- Data transfer: $36
- Lambda: $0.20
- Storage: $1
- **Total: ~$44-45/month**

**High usage (1TB+ data transfer):**
- EC2 t3.micro: $7-8
- Data transfer: $81+
- Lambda: $0.20
- Storage: $1
- **Total: ~$89+/month**

## Cost Optimization Strategies

### 1. Use AWS Free Tier (New Accounts)
- **First 12 months**: 750 hours/month of t2.micro/t3.micro FREE
- **First 12 months**: 100GB data transfer FREE
- **Savings**: ~$7-8/month for first year

### 2. Reserved Instances (1-3 year commitment)
- **1-year Reserved**: ~40% discount
- **3-year Reserved**: ~60% discount
- **Example**: t3.micro 1-year = ~$4-5/month instead of $7-8

### 3. Spot Instances (Not Recommended)
- **Cheaper**: Up to 90% discount
- **Risk**: Can be terminated with 2-minute notice
- **Not suitable**: For always-on DNS/proxy service

### 4. Smaller Instance Types
- **t4g.nano** (ARM-based): ~$3-4/month
  - 2 vCPU, 0.5GB RAM
  - **Warning**: May not handle many concurrent proxy connections
  - **Good for**: Testing, low usage

### 5. Data Transfer Optimization
- **CloudFront CDN**: Can reduce data transfer costs
- **Compression**: Enable gzip/brotli in Squid
- **Caching**: Cache static content (already disabled for streaming)
- **Monitor usage**: Set up CloudWatch alarms

### 6. Regional Optimization
- **us-east-2 (Ohio)**: Already one of the cheapest regions
- **us-east-1 (N. Virginia)**: Slightly cheaper but more expensive data transfer
- **Current choice is optimal**

## Cheaper Alternatives

### Option 1: Use t4g.nano (ARM-based)
**Savings**: ~$4/month
**Trade-off**: Less RAM, may struggle with high concurrent connections

### Option 2: Reserved Instance (1-year)
**Savings**: ~$3-4/month
**Trade-off**: 1-year commitment

### Option 3: Lightsail (Simplified)
- **$5/month**: 1GB RAM, 1 vCPU, 1TB transfer
- **$10/month**: 2GB RAM, 1 vCPU, 2TB transfer
- **Pros**: Predictable pricing, includes data transfer
- **Cons**: Less flexible, fewer features

### Option 4: DigitalOcean / Linode / Vultr
- **$6/month**: 1GB RAM, 1 vCPU, 1TB transfer
- **Pros**: Simpler pricing, includes data transfer
- **Cons**: Not AWS, would need to migrate

## Cost Monitoring

### Set Up CloudWatch Alarms

1. **Data Transfer Alarm**: Alert when approaching 100GB (free tier limit)
2. **EC2 Cost Alarm**: Alert when monthly cost exceeds threshold
3. **Billing Alarm**: Alert when total AWS bill exceeds budget

### Cost Tracking

- Use AWS Cost Explorer to track spending
- Tag resources for cost allocation
- Set up budgets in AWS Budgets

## Recommendations

### For Low Usage (< 100GB/month)
- **Current setup (t3.micro)**: ~$8-9/month ✅
- Consider Reserved Instance for 1-year: ~$4-5/month

### For Medium Usage (100-500GB/month)
- **Current setup**: ~$44-45/month
- Consider Lightsail $10/month plan (includes 2TB transfer)
- Or optimize with compression/caching

### For High Usage (1TB+/month)
- **Current setup**: ~$89+/month
- Consider Lightsail $20/month plan (includes 3TB transfer)
- Or use CloudFront CDN to reduce origin data transfer

## Cost Comparison Table

| Service | Monthly Cost | Data Transfer | Notes |
|---------|-------------|---------------|-------|
| **AWS EC2 t3.micro** | $7-8 | Pay per GB | Current setup |
| **AWS EC2 t4g.nano** | $3-4 | Pay per GB | Less RAM |
| **AWS Lightsail $5** | $5 | 1TB included | Simpler, less flexible |
| **AWS Lightsail $10** | $10 | 2TB included | Good for medium usage |
| **DigitalOcean $6** | $6 | 1TB included | Non-AWS option |
| **Vultr $6** | $6 | 1TB included | Non-AWS option |

## Bottom Line

**Your current setup is cost-effective for low-medium usage.**

**Main cost driver**: Data transfer (after first 100GB free)

**Best optimization**: 
1. Use Reserved Instance (1-year) for EC2: Save ~$3-4/month
2. Monitor data transfer usage
3. Consider Lightsail if you need predictable pricing with included transfer

**Monthly cost with current setup**: ~$8-9/month (low usage) to $44-89/month (high usage)

