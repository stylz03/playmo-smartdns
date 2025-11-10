#!/bin/bash
# Systemd service script for Playmo SmartDNS API

cd /opt/playmo-smartdns-api || exit 1

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Run with gunicorn
exec gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 30 --access-logfile - --error-logfile - app:app

