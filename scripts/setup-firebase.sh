#!/bin/bash
# Playmo SmartDNS Firebase Setup Script (Linux/Mac)

echo "🔥 Playmo SmartDNS Firebase Setup"
echo "================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
else
    echo "✅ Firebase CLI installed: $(firebase --version)"
fi

echo ""
echo "Step 1: Login to Firebase"
echo "You'll need to authenticate with your Google account."
read -p "Do you want to login to Firebase now? (y/n) " login

if [ "$login" = "y" ] || [ "$login" = "Y" ]; then
    echo "Opening Firebase login..."
    firebase login
else
    echo "Skipping login. Run 'firebase login' manually when ready."
fi

echo ""
echo "Step 2: Create Firebase Project"
echo ""
echo "You have two options:"
echo "1. Create project via Firebase Console (Recommended for first time)"
echo "   - Go to: https://console.firebase.google.com/"
echo "   - Click 'Add project'"
echo "   - Follow the wizard"
echo ""
echo "2. Create project via CLI (after login)"
echo "   - Run: firebase projects:create PROJECT_ID"
echo ""

read -p "Enter your Firebase Project ID (or press Enter to skip): " projectId

if [ -n "$projectId" ]; then
    echo ""
    echo "Step 3: Initialize Firestore"
    
    # Create .firebaserc if it doesn't exist
    if [ ! -f ".firebaserc" ]; then
        echo "Creating .firebaserc file..."
        cat > .firebaserc <<EOF
{
  "projects": {
    "default": "$projectId"
  }
}
EOF
    fi
    
    echo ""
    echo "Initializing Firestore..."
    echo "When prompted:"
    echo "  - Select 'Firestore'"
    echo "  - Choose 'Start in production mode' (we'll set rules later)"
    echo ""
    
    read -p "Run 'firebase init firestore' now? (y/n) " init
    if [ "$init" = "y" ] || [ "$init" = "Y" ]; then
        firebase init firestore
    fi
    
    echo ""
    echo "Step 4: Generate Service Account Key"
    echo ""
    echo "To generate service account credentials:"
    echo "1. Go to: https://console.firebase.google.com/project/$projectId/settings/serviceaccounts/adminsdk"
    echo "2. Click 'Generate new private key'"
    echo "3. Download the JSON file"
    echo "4. Copy the entire contents"
    echo "5. Add it to GitHub Secrets as FIREBASE_CREDENTIALS"
    echo ""
    
    echo "Or use this direct link:"
    echo "https://console.firebase.google.com/project/$projectId/settings/serviceaccounts/adminsdk"
    echo ""
    
    echo "Step 5: Set Firestore Security Rules"
    echo ""
    echo "After Firestore is initialized, update security rules:"
    echo "1. Go to Firestore → Rules"
    echo "2. Use the rules from docs/FIREBASE_SETUP.md"
    echo ""
    
    echo "✅ Setup instructions complete!"
    echo ""
    echo "Next steps:"
    echo "1. Add FIREBASE_CREDENTIALS to GitHub Secrets"
    echo "2. Push code to trigger deployment"
    echo "3. Test API: curl http://EC2_IP:5000/health"
else
    echo ""
    echo "Manual Setup Instructions:"
    echo "1. Go to https://console.firebase.google.com/"
    echo "2. Create a new project"
    echo "3. Enable Firestore Database"
    echo "4. Generate service account key"
    echo "5. See docs/FIREBASE_SETUP.md for detailed steps"
fi

echo ""

