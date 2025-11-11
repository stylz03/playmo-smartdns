# Generate QR Codes Locally (No EC2 Access Needed)

You can generate QR codes for WireGuard configs directly on your local machine without SSHing into EC2.

## Method 1: Python Script (Recommended) ⭐

### Install Python and QR code library:

```bash
# Install Python (if not already installed)
# Download from: https://www.python.org/downloads/

# Install qrcode library
pip install qrcode[pil]
```

### Generate QR code:

```bash
# If you have the config file locally
python scripts/generate-qr-local.py client1.conf

# Or specify output name
python scripts/generate-qr-local.py client1.conf my-client-qr
```

This creates:
- `client1.png` - PNG image (best for sharing)
- `client1.svg` - SVG (scalable)

## Method 2: PowerShell Script (Windows)

```powershell
# Run the PowerShell script
.\scripts\generate-qr-local.ps1 client1.conf

# Or with output name
.\scripts\generate-qr-local.ps1 client1.conf my-client-qr
```

**Note:** If Python is installed, it uses Python. Otherwise, it uses an online QR code generator.

## Method 3: Web-Based (Easiest!) 🌐

1. **Open the HTML file in your browser:**
   ```bash
   # Double-click or open in browser:
   scripts/generate-qr-online.html
   ```

2. **Paste your WireGuard config** into the text area

3. **Click "Generate QR Code"**

4. **Download or screenshot** the QR code

5. **Share with customer!**

No installation needed - works in any modern browser!

## Method 4: Online QR Code Generator

1. **Copy your WireGuard config** content
2. **Visit:** https://www.qr-code-generator.com/
3. **Paste config** in "Text" section
4. **Download QR code**

## Getting the Config File

If you need to get the config from EC2:

### Option A: View and Copy
```bash
ssh ubuntu@3.151.46.11
cat /tmp/client1.conf
# Copy the output and save locally as client1.conf
```

### Option B: Use SCP (if SSH keys set up)
```bash
scp ubuntu@3.151.46.11:/tmp/client1.conf .
```

### Option C: AWS Systems Manager
```bash
aws ssm send-command \
  --instance-ids i-XXXXXXXXX \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=['cat /tmp/client1.conf']" \
  --region us-east-2
```

## Workflow for Sharing with Customers

1. **Generate client config on EC2:**
   ```bash
   sudo bash /tmp/setup-client.sh client1
   ```

2. **Get config file locally** (view and copy, or SCP)

3. **Generate QR code locally:**
   - Use web-based: Open `generate-qr-online.html` → Paste config → Generate
   - Or Python: `python generate-qr-local.py client1.conf`

4. **Share QR code** with customer (email, messaging, etc.)

5. **Customer scans** with WireGuard app → Done! ✅

## Tips

- **PNG format** is best for sharing (small file size, works everywhere)
- **SVG format** is scalable (good for printing)
- **Web-based method** is easiest - no installation needed
- **Python method** works offline and gives best quality

## Troubleshooting

### Python not found
- Install Python from https://www.python.org/downloads/
- Make sure to check "Add Python to PATH" during installation

### qrcode library not found
```bash
pip install qrcode[pil]
```

### PowerShell script fails
- Install Python and use Method 1 instead
- Or use the web-based method (Method 3)

