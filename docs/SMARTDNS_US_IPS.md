# SmartDNS US IP Configuration

## Current Issue

The DNS server is forwarding to Google DNS (8.8.8.8), which returns IPs based on the query source location. While the EC2 instance is in us-east-2 (USA), this doesn't guarantee US IPs for all streaming services.

## Solution: Static A Records

For reliable geo-unblocking, we need to configure BIND9 to return specific US CDN IPs for streaming domains.

## Implementation Options

### Option 1: Use US-based DNS Resolvers (Recommended)
Configure BIND9 to forward to US-based SmartDNS provider DNS servers that return US IPs.

### Option 2: Static A Records
Configure BIND9 with static A records pointing to known US CDN IPs for each streaming service.

### Option 3: Hybrid Approach
Use static A records for major services and forward to US-based resolvers for others.

## Next Steps

1. Test current IPs to see if they're US-based
2. Configure US-based DNS resolvers or static A records
3. Test streaming services to verify geo-unblocking

