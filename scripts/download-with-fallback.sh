#!/bin/bash
# Download script with multiple fallback methods

URL="${1}"
OUTPUT="${2}"
TIMEOUT="${3:-10}"

if [ -z "$URL" ] || [ -z "$OUTPUT" ]; then
    echo "Usage: $0 <url> <output_file> [timeout]"
    exit 1
fi

echo "Downloading: $URL"
echo "Output: $OUTPUT"

# Method 1: curl with timeout and retry
if timeout "$TIMEOUT" curl -s -f --retry 2 --retry-delay 1 "$URL" -o "$OUTPUT" 2>/dev/null; then
    if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
        echo "✅ Download successful (curl)"
        exit 0
    fi
fi

# Method 2: wget (if available)
if command -v wget >/dev/null 2>&1; then
    if timeout "$TIMEOUT" wget -q --timeout=5 --tries=2 "$URL" -O "$OUTPUT" 2>/dev/null; then
        if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
            echo "✅ Download successful (wget)"
            exit 0
        fi
    fi
fi

# Method 3: Try with different user agent
if timeout "$TIMEOUT" curl -s -f -A "Mozilla/5.0" "$URL" -o "$OUTPUT" 2>/dev/null; then
    if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
        echo "✅ Download successful (curl with user agent)"
        exit 0
    fi
fi

echo "❌ All download methods failed"
exit 1

