# How to Download WireGuard Client Config

If you're getting "Permission denied (publickey)" when using SCP, here are several ways to get your client config file.

## Option 1: View and Copy (Easiest) ⭐

**On EC2:**
```bash
ssh ubuntu@3.151.46.11
cat /tmp/client1.conf
```

**Then:**
1. Copy the entire output
2. On your local machine, create `client1.conf`
3. Paste the content
4. Save the file

## Option 2: Use SSH Key Authentication

### Generate SSH Key (if you don't have one)

**On Windows (PowerShell):**
```powershell
ssh-keygen -t ed25519 -C "your_email@example.com"
```

This creates:
- `~/.ssh/id_ed25519` (private key)
- `~/.ssh/id_ed25519.pub` (public key)

### Copy Public Key to EC2

**On Windows:**
```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub
```

**Copy the output, then on EC2:**
```bash
ssh ubuntu@3.151.46.11
mkdir -p ~/.ssh
echo "PASTE_YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

**Then download:**
```powershell
scp ubuntu@3.151.46.11:/tmp/client1.conf .
```

## Option 3: Use AWS Systems Manager (SSM)

If you have AWS CLI configured:

```powershell
aws ssm send-command `
  --instance-ids i-XXXXXXXXX `
  --document-name "AWS-RunShellScript" `
  --parameters "commands=['cat /tmp/client1.conf']" `
  --region us-east-2 `
  --output text

# Then get the output
aws ssm get-command-invocation `
  --command-id <command-id> `
  --instance-id i-XXXXXXXXX `
  --region us-east-2
```

## Option 4: Use WinSCP (Windows GUI)

1. Download WinSCP: https://winscp.net/
2. Connect to `ubuntu@3.151.46.11` using your SSH key
3. Navigate to `/tmp/`
4. Download `client1.conf`

## Option 5: Use EC2 Instance Connect (Browser)

1. Go to AWS Console → EC2 → Instances
2. Select your instance
3. Click **"Connect"** → **"EC2 Instance Connect"**
4. Run: `cat /tmp/client1.conf`
5. Copy the output

## Quick Test

After getting the config file, verify it looks correct:

```ini
# WireGuard Client Configuration: client1
# Split-tunnel: Only streaming services route through VPN
# Generated: [date]

[Interface]
PrivateKey = [your-private-key]
Address = 10.0.0.1/24
DNS = 3.151.46.11  # SmartDNS for browsers (optional)

[Peer]
PublicKey = 5Q2rB8PMKL/oekh5qdB6bdkeyM58JGs9vHo9gG3z7jI=
Endpoint = 3.151.46.11:51820
AllowedIPs = [list of ~115 IP ranges]
PersistentKeepalive = 25
```

## Import into WireGuard

Once you have `client1.conf`:

1. **Android/iOS**: WireGuard app → + → Import from file
2. **Windows/Mac**: WireGuard client → Import tunnel

Then connect and test!

