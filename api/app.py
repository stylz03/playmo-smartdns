#!/usr/bin/env python3
"""
Playmo SmartDNS Firebase API
REST API for managing clients, IP whitelisting, and Firestore operations
"""

import os
import json
import logging
import subprocess
from datetime import datetime, timezone
from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore, auth
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for Firebase Studio and mobile apps

# Initialize Firebase Admin SDK
db = None
try:
    # Get Firebase credentials from environment variable
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

# Lambda function URL for IP whitelisting
LAMBDA_WHITELIST_URL = os.environ.get('LAMBDA_WHITELIST_URL', '')
SECURITY_GROUP_ID = os.environ.get('SECURITY_GROUP_ID', '')

# Collections
COLLECTION_CLIENTS = 'clients'
COLLECTION_IPS = 'ip_addresses'
COLLECTION_WHITELIST = 'whitelist_entries'
COLLECTION_LOGS = 'api_logs'


def log_api_call(endpoint, method, status, data=None):
    """Log API calls to Firestore"""
    if not db:
        return
    
    try:
        db.collection(COLLECTION_LOGS).add({
            'endpoint': endpoint,
            'method': method,
            'status': status,
            'data': data,
            'timestamp': firestore.SERVER_TIMESTAMP,
            'ip': request.remote_addr
        })
    except Exception as e:
        logger.error(f"Failed to log API call: {e}")


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'firebase_connected': db is not None,
        'lambda_configured': bool(LAMBDA_WHITELIST_URL),
        'timestamp': datetime.now(timezone.utc).isoformat()
    }), 200


@app.route('/api/clients', methods=['GET'])
def get_clients():
    """Get all clients"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        clients_ref = db.collection(COLLECTION_CLIENTS)
        clients = []
        
        for doc in clients_ref.stream():
            client_data = doc.to_dict()
            client_data['id'] = doc.id
            clients.append(client_data)
        
        log_api_call('/api/clients', 'GET', 200)
        return jsonify({'clients': clients}), 200
    except Exception as e:
        logger.error(f"Error getting clients: {e}")
        log_api_call('/api/clients', 'GET', 500, str(e))
        return jsonify({'error': str(e)}), 500


@app.route('/api/clients', methods=['POST'])
def create_client():
    """Create a new client"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'email']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Create client document
        client_data = {
            'name': data['name'],
            'email': data['email'],
            'status': data.get('status', 'active'),
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
            'ip_addresses': [],
            'metadata': data.get('metadata', {})
        }
        
        doc_ref = db.collection(COLLECTION_CLIENTS).add(client_data)
        client_data['id'] = doc_ref[1].id
        
        log_api_call('/api/clients', 'POST', 201, {'client_id': doc_ref[1].id})
        return jsonify({'client': client_data}), 201
    except Exception as e:
        logger.error(f"Error creating client: {e}")
        log_api_call('/api/clients', 'POST', 500, str(e))
        return jsonify({'error': str(e)}), 500


@app.route('/api/clients/<client_id>', methods=['GET'])
def get_client(client_id):
    """Get a specific client"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        doc_ref = db.collection(COLLECTION_CLIENTS).document(client_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return jsonify({'error': 'Client not found'}), 404
        
        client_data = doc.to_dict()
        client_data['id'] = doc.id
        
        log_api_call(f'/api/clients/{client_id}', 'GET', 200)
        return jsonify({'client': client_data}), 200
    except Exception as e:
        logger.error(f"Error getting client: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/clients/<client_id>/ips', methods=['POST'])
def add_client_ip(client_id):
    """Add or update IP address for a client"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        data = request.get_json()
        ip_address = data.get('ip_address')
        
        if not ip_address:
            return jsonify({'error': 'Missing ip_address field'}), 400
        
        # Validate IP format
        import ipaddress
        try:
            ipaddress.ip_address(ip_address)
        except ValueError:
            return jsonify({'error': 'Invalid IP address format'}), 400
        
        # Get client
        client_ref = db.collection(COLLECTION_CLIENTS).document(client_id)
        client_doc = client_ref.get()
        
        if not client_doc.exists:
            return jsonify({'error': 'Client not found'}), 404
        
        # Add IP to client's IP list
        client_data = client_doc.to_dict()
        ip_list = client_data.get('ip_addresses', [])
        
        # Update or add IP
        ip_entry = {
            'ip': ip_address,
            'updated_at': firestore.SERVER_TIMESTAMP,
            'source': data.get('source', 'manual'),
            'is_active': True
        }
        
        # Check if IP already exists
        ip_exists = False
        for i, existing_ip in enumerate(ip_list):
            if existing_ip.get('ip') == ip_address:
                ip_list[i] = ip_entry
                ip_exists = True
                break
        
        if not ip_exists:
            ip_entry['created_at'] = firestore.SERVER_TIMESTAMP
            ip_list.append(ip_entry)
        
        # Update client document
        client_ref.update({
            'ip_addresses': ip_list,
            'updated_at': firestore.SERVER_TIMESTAMP
        })
        
        # Create IP address document
        ip_doc_data = {
            'client_id': client_id,
            'ip_address': ip_address,
            'is_whitelisted': False,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
            'source': data.get('source', 'manual')
        }
        
        db.collection(COLLECTION_IPS).add(ip_doc_data)
        
        # Auto-whitelist if Lambda URL is configured
        if LAMBDA_WHITELIST_URL:
            try:
                whitelist_response = requests.post(
                    LAMBDA_WHITELIST_URL,
                    json={'ip': ip_address},
                    timeout=5
                )
                if whitelist_response.status_code == 200:
                    # Update IP document with whitelist status
                    ip_doc_data['is_whitelisted'] = True
                    ip_doc_data['whitelisted_at'] = firestore.SERVER_TIMESTAMP
                    
                    # Note: IP whitelisting is handled by security group rules
                    # sniproxy doesn't need ACL updates as it forwards transparently
                    logger.info(f"IP {ip_address} whitelisted via security group")
            except Exception as e:
                logger.warning(f"Failed to whitelist IP via Lambda: {e}")
        
        log_api_call(f'/api/clients/{client_id}/ips', 'POST', 201, {'ip': ip_address})
        return jsonify({
            'message': 'IP address added successfully',
            'ip': ip_address,
            'whitelisted': ip_doc_data.get('is_whitelisted', False)
        }), 201
    except Exception as e:
        logger.error(f"Error adding client IP: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/ips/whitelist', methods=['POST'])
def whitelist_ip():
    """Manually whitelist an IP address"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        data = request.get_json()
        ip_address = data.get('ip_address')
        client_id = data.get('client_id')
        
        if not ip_address:
            return jsonify({'error': 'Missing ip_address field'}), 400
        
        # Call Lambda function to whitelist
        if LAMBDA_WHITELIST_URL:
            try:
                response = requests.post(
                    LAMBDA_WHITELIST_URL,
                    json={'ip': ip_address, 'proto': data.get('proto', 'udp')},
                    timeout=5
                )
                
                if response.status_code == 200:
                    # Create whitelist entry
                    whitelist_data = {
                        'ip_address': ip_address,
                        'client_id': client_id,
                        'whitelisted_at': firestore.SERVER_TIMESTAMP,
                        'whitelisted_by': data.get('whitelisted_by', 'system'),
                        'protocol': data.get('proto', 'udp')
                    }
                    
                    db.collection(COLLECTION_WHITELIST).add(whitelist_data)
                    
                    # Update IP document
                    ip_query = db.collection(COLLECTION_IPS).where('ip_address', '==', ip_address)
                    for doc in ip_query.stream():
                        doc.reference.update({
                            'is_whitelisted': True,
                            'whitelisted_at': firestore.SERVER_TIMESTAMP
                        })
                    
                    return jsonify({
                        'message': 'IP whitelisted successfully',
                        'ip': ip_address
                    }), 200
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
    """Get dashboard statistics"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        stats = {
            'total_clients': len(list(db.collection(COLLECTION_CLIENTS).stream())),
            'total_ips': len(list(db.collection(COLLECTION_IPS).stream())),
            'whitelisted_ips': len([doc for doc in db.collection(COLLECTION_IPS).stream() 
                                   if doc.to_dict().get('is_whitelisted', False)]),
            'total_whitelist_entries': len(list(db.collection(COLLECTION_WHITELIST).stream()))
        }
        
        return jsonify({'stats': stats}), 200
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)

