#!/bin/bash
# Create app.py with the correct content

cat > /opt/playmo-smartdns-api/app.py <<'APIPY'
#!/usr/bin/env python3
"""
Playmo SmartDNS Firebase API
REST API for managing clients, IP whitelisting, and Firestore operations
"""

import os
import json
import logging
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
        log_api_call(f'/api/clients/{client_id}', 'GET', 500, str(e))
        return jsonify({'error': str(e)}), 500


@app.route('/api/clients/<client_id>', methods=['PUT'])
def update_client(client_id):
    """Update an existing client"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        data = request.get_json()
        doc_ref = db.collection(COLLECTION_CLIENTS).document(client_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return jsonify({'error': 'Client not found'}), 404
        
        update_data = {
            'updated_at': firestore.SERVER_TIMESTAMP
        }
        if 'name' in data:
            update_data['name'] = data['name']
        if 'email' in data:
            update_data['email'] = data['email']
        if 'status' in data:
            update_data['status'] = data['status']
        if 'metadata' in data:
            update_data['metadata'] = data['metadata']
        
        doc_ref.update(update_data)
        
        updated_client = doc_ref.get().to_dict()
        updated_client['id'] = doc.id
        
        log_api_call(f'/api/clients/{client_id}', 'PUT', 200, data)
        return jsonify({'client': updated_client}), 200
    except Exception as e:
        logger.error(f"Error updating client: {e}")
        log_api_call(f'/api/clients/{client_id}', 'PUT', 500, str(e))
        return jsonify({'error': str(e)}), 500


@app.route('/api/clients/<client_id>', methods=['DELETE'])
def delete_client(client_id):
    """Delete a client"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        doc_ref = db.collection(COLLECTION_CLIENTS).document(client_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return jsonify({'error': 'Client not found'}), 404
        
        doc_ref.delete()
        
        # Delete associated IP addresses and whitelist entries
        ip_query = db.collection(COLLECTION_IPS).where('client_id', '==', client_id)
        for ip_doc in ip_query.stream():
            ip_doc.reference.delete()
        
        whitelist_query = db.collection(COLLECTION_WHITELIST).where('client_id', '==', client_id)
        for wl_doc in whitelist_query.stream():
            wl_doc.reference.delete()
        
        log_api_call(f'/api/clients/{client_id}', 'DELETE', 200)
        return jsonify({'message': 'Client deleted successfully'}), 200
    except Exception as e:
        logger.error(f"Error deleting client: {e}")
        log_api_call(f'/api/clients/{client_id}', 'DELETE', 500, str(e))
        return jsonify({'error': str(e)}), 500


@app.route('/api/clients/<client_id>/ips', methods=['GET'])
def get_client_ips(client_id):
    """Get IP addresses for a specific client"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        ips_ref = db.collection(COLLECTION_IPS).where('client_id', '==', client_id)
        ips = []
        for doc in ips_ref.stream():
            ip_data = doc.to_dict()
            ip_data['id'] = doc.id
            ips.append(ip_data)
        
        log_api_call(f'/api/clients/{client_id}/ips', 'GET', 200)
        return jsonify({'ip_addresses': ips}), 200
    except Exception as e:
        logger.error(f"Error getting client IPs: {e}")
        log_api_call(f'/api/clients/{client_id}/ips', 'GET', 500, str(e))
        return jsonify({'error': str(e)}), 500


@app.route('/api/clients/<client_id>/ips', methods=['POST'])
def add_client_ip(client_id):
    """Add an IP address to a client and whitelist it"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        data = request.get_json()
        ip_address = data.get('ip_address')
        
        if not ip_address:
            return jsonify({'error': 'Missing ip_address field'}), 400
        
        # Check if IP already exists for this client
        existing_ip_query = db.collection(COLLECTION_IPS).where('client_id', '==', client_id).where('ip_address', '==', ip_address).limit(1).stream()
        if len(list(existing_ip_query)) > 0:
            return jsonify({'error': 'IP address already registered for this client'}), 409

        # Add IP to client's IP list
        ip_data = {
            'ip_address': ip_address,
            'client_id': client_id,
            'added_at': firestore.SERVER_TIMESTAMP,
            'last_seen_at': firestore.SERVER_TIMESTAMP,
            'is_whitelisted': False,
            'metadata': data.get('metadata', {})
        }
        
        ip_doc_ref = db.collection(COLLECTION_IPS).add(ip_data)
        ip_data['id'] = ip_doc_ref[1].id

        # Call Lambda function to whitelist
        if LAMBDA_WHITELIST_URL:
            try:
                response = requests.post(
                    LAMBDA_WHITELIST_URL,
                    json={'ip': ip_address, 'proto': data.get('proto', 'udp')},
                    timeout=5
                )
                
                if response.status_code == 200:
                    # Update IP document to reflect whitelisting
                    db.collection(COLLECTION_IPS).document(ip_doc_ref[1].id).update({
                        'is_whitelisted': True,
                        'whitelisted_at': firestore.SERVER_TIMESTAMP
                    })
                    
                    # Create whitelist entry
                    whitelist_data = {
                        'ip_address': ip_address,
                        'client_id': client_id,
                        'whitelisted_at': firestore.SERVER_TIMESTAMP,
                        'whitelisted_by': 'api',
                        'protocol': data.get('proto', 'udp')
                    }
                    db.collection(COLLECTION_WHITELIST).add(whitelist_data)
                    
                    log_api_call(f'/api/clients/{client_id}/ips', 'POST', 201, {'ip_id': ip_doc_ref[1].id, 'whitelisted': True})
                    return jsonify({'ip_address': ip_data, 'message': 'IP added and whitelisted'}), 201
                else:
                    logger.error(f"Lambda whitelisting failed for {ip_address}: {response.text}")
                    log_api_call(f'/api/clients/{client_id}/ips', 'POST', 500, f"Lambda failed: {response.text}")
                    return jsonify({'error': 'Failed to whitelist IP via Lambda', 'lambda_response': response.text}), 500
            except requests.exceptions.RequestException as req_e:
                logger.error(f"Network error calling Lambda: {req_e}")
                log_api_call(f'/api/clients/{client_id}/ips', 'POST', 500, f"Lambda network error: {req_e}")
                return jsonify({'error': f'Network error calling Lambda: {req_e}'}), 500
        else:
            log_api_call(f'/api/clients/{client_id}/ips', 'POST', 201, {'ip_id': ip_doc_ref[1].id, 'whitelisted': False})
            return jsonify({'ip_address': ip_data, 'message': 'IP added, Lambda whitelisting skipped (URL not configured)'}), 201
    except Exception as e:
        logger.error(f"Error adding client IP: {e}")
        log_api_call(f'/api/clients/{client_id}/ips', 'POST', 500, str(e))
        return jsonify({'error': str(e)}), 500


@app.route('/api/ips/<ip_id>', methods=['DELETE'])
def remove_client_ip(ip_id):
    """Remove an IP address from a client"""
    if not db:
        return jsonify({'error': 'Firebase not initialized'}), 500
    
    try:
        ip_doc_ref = db.collection(COLLECTION_IPS).document(ip_id)
        ip_doc = ip_doc_ref.get()
        
        if not ip_doc.exists:
            return jsonify({'error': 'IP address not found'}), 404
        
        ip_doc_ref.delete()
        
        # Optionally call Lambda to de-whitelist (not implemented in current Lambda)
        
        log_api_call(f'/api/ips/{ip_id}', 'DELETE', 200)
        return jsonify({'message': 'IP address removed successfully'}), 200
    except Exception as e:
        logger.error(f"Error removing client IP: {e}")
        log_api_call(f'/api/ips/{ip_id}', 'DELETE', 500, str(e))
        return jsonify({'error': str(e)}), 500


@app.route('/api/whitelist', methods=['POST'])
def whitelist_ip_manual():
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
                    logger.error(f"Lambda whitelisting failed for {ip_address}: {response.text}")
                    return jsonify({'error': 'Failed to whitelist IP', 'lambda_response': response.text}), 500
            except requests.exceptions.RequestException as req_e:
                logger.error(f"Network error calling Lambda: {req_e}")
                return jsonify({'error': f'Network error calling Lambda: {req_e}'}), 500
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
        total_clients = len(list(db.collection(COLLECTION_CLIENTS).stream()))
        total_ips = len(list(db.collection(COLLECTION_IPS).stream()))
        whitelisted_ips = len([doc for doc in db.collection(COLLECTION_IPS).stream() 
                              if doc.to_dict().get('is_whitelisted', False)])
        total_whitelist_entries = len(list(db.collection(COLLECTION_WHITELIST).stream()))

        stats = {
            'total_clients': total_clients,
            'total_ips': total_ips,
            'whitelisted_ips': whitelisted_ips,
            'total_whitelist_entries': total_whitelist_entries
        }
        
        log_api_call('/api/stats', 'GET', 200)
        return jsonify({'stats': stats}), 200
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        log_api_call('/api/stats', 'GET', 500, str(e))
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
APIPY

