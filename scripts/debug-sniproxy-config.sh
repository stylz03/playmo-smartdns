#!/bin/bash
# Debug sniproxy config to see actual error
# Run: sudo bash debug-sniproxy-config.sh

set -e

echo "=========================================="
echo "Debugging sniproxy config"
echo "=========================================="

# Check if config exists
if [ ! -f /etc/sniproxy/sniproxy.conf ]; then
    echo "❌ Config file not found!"
    exit 1
fi

echo ""
echo "1. Config file info:"
ls -lh /etc/sniproxy/sniproxy.conf
echo "Lines: $(wc -l < /etc/sniproxy/sniproxy.conf)"
echo "Size: $(wc -c < /etc/sniproxy/sniproxy.conf) bytes"

echo ""
echo "2. First 20 lines:"
head -20 /etc/sniproxy/sniproxy.conf

echo ""
echo "3. Last 20 lines:"
tail -20 /etc/sniproxy/sniproxy.conf

echo ""
echo "4. Checking for common issues..."
# Check for unmatched braces
OPEN_BRACES=$(grep -o '{' /etc/sniproxy/sniproxy.conf | wc -l)
CLOSE_BRACES=$(grep -o '}' /etc/sniproxy/sniproxy.conf | wc -l)
echo "Open braces: $OPEN_BRACES"
echo "Close braces: $CLOSE_BRACES"
if [ "$OPEN_BRACES" != "$CLOSE_BRACES" ]; then
    echo "❌ Unmatched braces!"
fi

# Check for proto directives
echo ""
echo "5. Checking proto directives:"
grep -n "proto" /etc/sniproxy/sniproxy.conf

echo ""
echo "6. Testing with sniproxy (showing full error):"
sudo /usr/local/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f 2>&1 || true

echo ""
echo "7. Checking file encoding:"
file /etc/sniproxy/sniproxy.conf

echo ""
echo "8. Checking for non-printable characters:"
if grep -P '[^\x20-\x7E\n\r]' /etc/sniproxy/sniproxy.conf > /dev/null; then
    echo "⚠️ Found non-printable characters"
    od -c /etc/sniproxy/sniproxy.conf | head -20
else
    echo "✅ No non-printable characters found"
fi

