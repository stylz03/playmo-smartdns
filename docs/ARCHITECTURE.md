# Playmo SmartDNS Architecture

## System Overview

Playmo SmartDNS is a multi-component system that provides intelligent DNS forwarding for streaming services with client management and automated IP whitelisting.

## Components

### 1. EC2 Instance (DNS Server)
- **Service**: Bind9 DNS server
- **Function**: Forwards streaming domain queries to Google/Cloudflare DNS
- **Location**: AWS EC2 (us-east-2)
- **IP**: Static Elastic IP

### 2. Firebase Integration
- **Service**: Firestore Database + Firebase Admin SDK
- **Function**: Client management, IP tracking, dashboard data
- **Collections**:
  - `clients`: Client information
  - `ip_addresses`: IP address tracking
  - `whitelist_entries`: Whitelist history
  - `api_logs`: API usage logs

### 3. REST API (Flask)
- **Service**: Python Flask API on EC2
- **Port**: 5000
- **Function**: 
  - CRUD operations for clients
  - IP management
  - Automatic whitelisting
  - Statistics and reporting

### 4. Lambda Function
- **Service**: AWS Lambda
- **Function**: IP whitelisting via security group updates
- **Trigger**: API calls from EC2 instance
- **URL**: Public function URL

### 5. GitHub Actions
- **Function**: CI/CD pipeline
  - Terraform deployment
  - Secret injection
  - Resource import/management
  - Testing and validation

## Data Flow

### Client IP Registration
```
Client App → API (EC2:5000) → Firestore → Lambda → Security Group Update
```

### DNS Query
```
Client Device → SmartDNS (EC2:53) → Google DNS/Cloudflare → Response
```

### Dashboard View
```
Firebase Studio → Firestore → Real-time Data Visualization
```

## Security Architecture

### Network Security
- Security Group with restricted access
- SSH access limited to admin IP
- API access configurable via `api_cidr`
- DNS access open (or whitelisted)

### Application Security
- Firebase service account credentials (stored in GitHub Secrets)
- Environment variables for sensitive data
- Firestore security rules
- API authentication (to be implemented)

## Redundancy & High Availability

### Current Setup
- Single EC2 instance
- Elastic IP for static addressing
- Auto-restart via systemd

### Recommended Enhancements

#### 1. Multi-Region Deployment
- Deploy EC2 instances in multiple AWS regions
- Use Route 53 for DNS failover
- Load balance API requests

#### 2. Auto-Scaling
- Auto Scaling Group for EC2
- Health checks and auto-recovery
- Multiple availability zones

#### 3. Database Redundancy
- Firestore has built-in redundancy
- Consider backup strategy
- Multi-region Firestore (if needed)

#### 4. API Load Balancing
- Application Load Balancer (ALB)
- Multiple EC2 instances behind ALB
- Health checks and auto-scaling

#### 5. Monitoring & Alerting
- CloudWatch alarms
- SNS notifications
- Health check endpoints
- Uptime monitoring

## Automation Features

### Current
- Automatic IP whitelisting via Lambda
- GitHub Actions CI/CD
- Auto-restart on failure

### Future Enhancements
- IP change detection (CloudWatch Events)
- Automatic client provisioning
- Mobile app push notifications
- Scheduled IP rotation
- Usage analytics and reporting

## Cost Optimization

### Current Costs
- EC2 t3.micro: ~$7.50/month
- Elastic IP: Free (when associated)
- Lambda: Free tier (1M requests/month)
- Firestore: Pay-as-you-go (very low for small scale)

### Optimization Strategies
- Use Reserved Instances for predictable workloads
- Implement auto-scaling to scale down during low usage
- Use CloudWatch to monitor and optimize
- Consider Spot Instances for non-critical workloads

## Mobile App Architecture

### Android TV / Google TV
```
App → Firebase Auth → Firestore → API → Lambda → Security Group
```

### tvOS (Apple TV)
```
App → Firebase Auth → Firestore → API → Lambda → Security Group
```

### Features
- User authentication
- IP registration
- Automatic whitelisting
- Status monitoring
- Push notifications

## Deployment Flow

1. **Code Push** → GitHub
2. **GitHub Actions Triggered**
3. **Terraform Plan** → Review changes
4. **Import Existing Resources** → Handle duplicates
5. **Terraform Apply** → Deploy infrastructure
6. **User Data Script** → Install services
7. **API Service Start** → Flask API running
8. **Health Checks** → Verify deployment
9. **Notifications** → Slack/webhook

## Monitoring & Logging

### Logs
- API logs: Firestore `api_logs` collection
- System logs: CloudWatch Logs
- Application logs: EC2 systemd journal

### Metrics
- API response times
- DNS query volume
- Client count
- IP whitelist status
- Error rates

## Future Roadmap

1. **Multi-tenant Support**: Separate clients with isolated resources
2. **Advanced Analytics**: Usage patterns, performance metrics
3. **Mobile Apps**: Native Android TV, Google TV, tvOS apps
4. **API Gateway**: AWS API Gateway for better API management
5. **CDN Integration**: CloudFront for API caching
6. **Web Dashboard**: React/Vue dashboard for management
7. **Automated Testing**: Integration tests, load testing
8. **Disaster Recovery**: Backup and restore procedures

