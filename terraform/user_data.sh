#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get upgrade -y
apt-get install -y bind9 bind9utils bind9-dnsutils unattended-upgrades fail2ban

# Bind9 global options
cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

# Inject selective forward zones
cat > /etc/bind/named.conf.local <<'EOF'
${NAMED_CONF_LOCAL}
EOF

systemctl enable bind9
systemctl restart bind9

# Security hardening
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || true
systemctl restart ssh || true

dpkg-reconfigure -plow unattended-upgrades || true

systemctl enable fail2ban
systemctl start fail2ban

# Install Playmo SmartDNS API
echo "Installing Playmo SmartDNS API..."
apt-get install -y python3 python3-pip python3-venv git curl

# Create API directory
mkdir -p /opt/playmo-smartdns-api
cd /opt/playmo-smartdns-api

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install flask==3.0.0 flask-cors==4.0.0 firebase-admin==6.4.0 gunicorn==21.2.0 requests==2.31.0 python-dotenv==1.0.0

# Download API app.py from GitHub (raw content)
echo "Downloading API application..."
curl -s https://raw.githubusercontent.com/stylz03/playmo-smartdns/main/api/app.py -o /opt/playmo-smartdns-api/app.py || {
    # Fallback: create minimal app.py if download fails
    cat > /opt/playmo-smartdns-api/app.py <<'APIPY'
#!/usr/bin/env python3
import os, json, logging
from datetime import datetime, timezone
from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore
import requests

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

db = None
try:
    firebase_creds_json = os.environ.get('FIREBASE_CREDENTIALS')
    if firebase_creds_json:
        cred_dict = json.loads(firebase_creds_json)
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        logger.info("Firebase Admin SDK initialized successfully")
    else:
        logger.warning("FIREBASE_CREDENTIALS not set, Firebase features disabled")
except Exception as e:
    logger.error(f"Failed to initialize Firebase: {e}")

LAMBDA_WHITELIST_URL = os.environ.get('LAMBDA_WHITELIST_URL', '')
COLLECTION_CLIENTS = 'clients'
COLLECTION_IPS = 'ip_addresses'
COLLECTION_WHITELIST = 'whitelist_entries'
COLLECTION_LOGS = 'api_logs'

def log_api_call(endpoint, method, status, data=None):
    if not db: return
    try:
        db.collection(COLLECTION_LOGS).add({
            'endpoint': endpoint, 'method': method, 'status': status, 'data': data,
            'timestamp': firestore.SERVER_TIMESTAMP, 'ip': request.remote_addr
        })
    except Exception as e:
        logger.error(f"Failed to log API call: {e}")

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'firebase_connected': db is not None,
        'lambda_configured': bool(LAMBDA_WHITELIST_URL),
        'timestamp': datetime.now(timezone.utc).isoformat()
    }), 200

@app.route('/api/clients', methods=['GET'])
def get_clients():
    if not db: return jsonify({'error': 'Firebase not initialized'}), 500
    try:
        clients = [dict(doc.to_dict(), id=doc.id) for doc in db.collection(COLLECTION_CLIENTS).stream()]
        log_api_call('/api/clients', 'GET', 200)
        return jsonify({'clients': clients}), 200
    except Exception as e:
        logger.error(f"Error getting clients: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/clients', methods=['POST'])
def create_client():
    if not db: return jsonify({'error': 'Firebase not initialized'}), 500
    try:
        data = request.get_json()
        if 'name' not in data or 'email' not in data:
            return jsonify({'error': 'Missing required fields: name, email'}), 400
        client_data = {
            'name': data['name'], 'email': data['email'], 'status': data.get('status', 'active'),
            'created_at': firestore.SERVER_TIMESTAMP, 'updated_at': firestore.SERVER_TIMESTAMP,
            'ip_addresses': [], 'metadata': data.get('metadata', {})
        }
        doc_ref = db.collection(COLLECTION_CLIENTS).add(client_data)
        client_data['id'] = doc_ref[1].id
        log_api_call('/api/clients', 'POST', 201, {'client_id': doc_ref[1].id})
        return jsonify({'client': client_data}), 201
    except Exception as e:
        logger.error(f"Error creating client: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/clients/<client_id>', methods=['GET'])
def get_client(client_id):
    if not db: return jsonify({'error': 'Firebase not initialized'}), 500
    try:
        doc = db.collection(COLLECTION_CLIENTS).document(client_id).get()
        if not doc.exists: return jsonify({'error': 'Client not found'}), 404
        client_data = dict(doc.to_dict(), id=doc.id)
        log_api_call(f'/api/clients/{client_id}', 'GET', 200)
        return jsonify({'client': client_data}), 200
    except Exception as e:
        logger.error(f"Error getting client: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/clients/<client_id>/ips', methods=['POST'])
def add_client_ip(client_id):
    if not db: return jsonify({'error': 'Firebase not initialized'}), 500
    try:
        data = request.get_json()
        ip_address = data.get('ip_address')
        if not ip_address: return jsonify({'error': 'Missing ip_address field'}), 400
        import ipaddress
        try: ipaddress.ip_address(ip_address)
        except ValueError: return jsonify({'error': 'Invalid IP address format'}), 400
        client_ref = db.collection(COLLECTION_CLIENTS).document(client_id)
        client_doc = client_ref.get()
        if not client_doc.exists: return jsonify({'error': 'Client not found'}), 404
        client_data = client_doc.to_dict()
        ip_list = client_data.get('ip_addresses', [])
        ip_entry = {'ip': ip_address, 'updated_at': firestore.SERVER_TIMESTAMP, 'source': data.get('source', 'manual'), 'is_active': True}
        ip_exists = False
        for i, existing_ip in enumerate(ip_list):
            if existing_ip.get('ip') == ip_address:
                ip_list[i] = ip_entry
                ip_exists = True
                break
        if not ip_exists:
            ip_entry['created_at'] = firestore.SERVER_TIMESTAMP
            ip_list.append(ip_entry)
        client_ref.update({'ip_addresses': ip_list, 'updated_at': firestore.SERVER_TIMESTAMP})
        ip_doc_data = {'client_id': client_id, 'ip_address': ip_address, 'is_whitelisted': False, 'created_at': firestore.SERVER_TIMESTAMP, 'updated_at': firestore.SERVER_TIMESTAMP, 'source': data.get('source', 'manual')}
        db.collection(COLLECTION_IPS).add(ip_doc_data)
        if LAMBDA_WHITELIST_URL:
            try:
                whitelist_response = requests.post(LAMBDA_WHITELIST_URL, json={'ip': ip_address, 'proto': 'udp'}, timeout=5)
                if whitelist_response.status_code == 200:
                    ip_doc_data['is_whitelisted'] = True
                    ip_doc_data['whitelisted_at'] = firestore.SERVER_TIMESTAMP
            except Exception as e:
                logger.warning(f"Failed to whitelist IP via Lambda: {e}")
        log_api_call(f'/api/clients/{client_id}/ips', 'POST', 201, {'ip': ip_address})
        return jsonify({'message': 'IP address added successfully', 'ip': ip_address, 'whitelisted': ip_doc_data.get('is_whitelisted', False)}), 201
    except Exception as e:
        logger.error(f"Error adding client IP: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/ips/whitelist', methods=['POST'])
def whitelist_ip():
    if not db: return jsonify({'error': 'Firebase not initialized'}), 500
    try:
        data = request.get_json()
        ip_address = data.get('ip_address')
        client_id = data.get('client_id')
        if not ip_address: return jsonify({'error': 'Missing ip_address field'}), 400
        if LAMBDA_WHITELIST_URL:
            try:
                response = requests.post(LAMBDA_WHITELIST_URL, json={'ip': ip_address, 'proto': data.get('proto', 'udp')}, timeout=5)
                if response.status_code == 200:
                    whitelist_data = {'ip_address': ip_address, 'client_id': client_id, 'whitelisted_at': firestore.SERVER_TIMESTAMP, 'whitelisted_by': data.get('whitelisted_by', 'system'), 'protocol': data.get('proto', 'udp')}
                    db.collection(COLLECTION_WHITELIST).add(whitelist_data)
                    ip_query = db.collection(COLLECTION_IPS).where('ip_address', '==', ip_address)
                    for doc in ip_query.stream():
                        doc.reference.update({'is_whitelisted': True, 'whitelisted_at': firestore.SERVER_TIMESTAMP})
                    return jsonify({'message': 'IP whitelisted successfully', 'ip': ip_address}), 200
                else:
                    return jsonify({'error': 'Failed to whitelist IP'}), 500
            except Exception as e:
                logger.error(f"Error calling Lambda: {e}")
                return jsonify({'error': str(e)}), 500
        else:
            return jsonify({'error': 'Lambda whitelist URL not configured'}), 500
    except Exception as e:
        logger.error(f"Error whitelisting IP: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/stats', methods=['GET'])
def get_stats():
    if not db: return jsonify({'error': 'Firebase not initialized'}), 500
    try:
        stats = {
            'total_clients': len(list(db.collection(COLLECTION_CLIENTS).stream())),
            'total_ips': len(list(db.collection(COLLECTION_IPS).stream())),
            'whitelisted_ips': len([doc for doc in db.collection(COLLECTION_IPS).stream() if doc.to_dict().get('is_whitelisted', False)]),
            'total_whitelist_entries': len(list(db.collection(COLLECTION_WHITELIST).stream()))
        }
        return jsonify({'stats': stats}), 200
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
APIPY
}

# Set Firebase credentials from environment variable
if [ -n "$FIREBASE_CREDENTIALS" ]; then
    echo "$FIREBASE_CREDENTIALS" > /opt/playmo-smartdns-api/firebase-credentials.json
    chmod 600 /opt/playmo-smartdns-api/firebase-credentials.json
fi

# Create systemd service
cat > /etc/systemd/system/playmo-smartdns-api.service <<EOFSERVICE
[Unit]
Description=Playmo SmartDNS Firebase API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/playmo-smartdns-api
Environment="PATH=/opt/playmo-smartdns-api/venv/bin"
Environment="FIREBASE_CREDENTIALS=${FIREBASE_CREDENTIALS}"
Environment="LAMBDA_WHITELIST_URL=${LAMBDA_WHITELIST_URL}"
ExecStart=/opt/playmo-smartdns-api/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 30 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Enable and start API service
systemctl daemon-reload
systemctl enable playmo-smartdns-api
systemctl start playmo-smartdns-api

echo "Playmo SmartDNS API installed successfully!"