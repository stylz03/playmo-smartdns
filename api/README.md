# Playmo SmartDNS API

REST API for managing SmartDNS clients, IP addresses, and whitelisting.

## Features

- **Client Management**: Create and manage clients
- **IP Tracking**: Track and manage client IP addresses
- **Automatic Whitelisting**: Automatically whitelist IPs via Lambda function
- **Firebase Integration**: Store all data in Firestore
- **Dashboard Ready**: Data structured for Firebase Studio visualization
- **Mobile App Support**: RESTful API for Android TV, Google TV, and tvOS apps

## API Endpoints

### Health Check
```
GET /health
```
Returns API health status and configuration.

### Clients

#### Get All Clients
```
GET /api/clients
```

#### Create Client
```
POST /api/clients
Body: {
  "name": "Client Name",
  "email": "client@example.com",
  "status": "active",
  "metadata": {}
}
```

#### Get Client
```
GET /api/clients/{client_id}
```

#### Add IP to Client
```
POST /api/clients/{client_id}/ips
Body: {
  "ip_address": "192.168.1.100",
  "source": "manual"
}
```

### IP Whitelisting

#### Whitelist IP
```
POST /api/ips/whitelist
Body: {
  "ip_address": "192.168.1.100",
  "client_id": "client_123",
  "proto": "udp"
}
```

### Statistics

#### Get Dashboard Stats
```
GET /api/stats
```

## Environment Variables

- `FIREBASE_CREDENTIALS`: Firebase service account JSON (string)
- `LAMBDA_WHITELIST_URL`: Lambda function URL for IP whitelisting
- `PORT`: API port (default: 5000)

## Firestore Collections

- `clients`: Client information
- `ip_addresses`: IP address tracking
- `whitelist_entries`: Whitelist history
- `api_logs`: API usage logs

## Development

### Local Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export FIREBASE_CREDENTIALS='{"type":"service_account",...}'
export LAMBDA_WHITELIST_URL='https://...'

# Run API
python app.py
```

### Testing

```bash
# Health check
curl http://localhost:5000/health

# Create client
curl -X POST http://localhost:5000/api/clients \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com"}'
```

## Production Deployment

The API is automatically deployed via Terraform user_data script:
- Installed as systemd service
- Auto-starts on boot
- Auto-restarts on failure
- Runs on port 5000

## Security

- Firebase credentials stored securely
- API access controlled via security group
- Consider adding authentication for production
- Firestore security rules should be configured

## Mobile App Integration

### Android TV / Google TV
```kotlin
// Example API call
val response = client.post("http://API_URL/api/clients/CLIENT_ID/ips") {
    contentType(ContentType.Application.Json)
    body = mapOf(
        "ip_address" to getLocalIpAddress(),
        "source" to "android_tv"
    )
}
```

### tvOS (Apple TV)
```swift
// Example API call
let url = URL(string: "http://API_URL/api/clients/\(clientId)/ips")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try JSONSerialization.data(withJSONObject: [
    "ip_address": getLocalIpAddress(),
    "source": "tvos"
])
```

