#!/bin/bash

echo "🔍 Getting SHA-1 fingerprint for Google Sign-In setup..."
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ keytool not found. Make sure Java is installed."
    echo "   You can install Java with: brew install openjdk"
    exit 1
fi

# Get SHA-1 fingerprint
echo "📱 SHA-1 Fingerprint for Android OAuth setup:"
echo ""

keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Copy the SHA-1 fingerprint above and use it in Google Cloud Console"
    echo "   for your Android OAuth client configuration."
else
    echo ""
    echo "❌ Could not find debug keystore. Make sure you have:"
    echo "   1. Android SDK installed"
    echo "   2. Run 'flutter doctor' to verify setup"
    echo "   3. The debug keystore should be at ~/.android/debug.keystore"
fi

echo ""
echo "📋 Your app details:"
echo "   Android Package: com.example.sampul_app_v2"
echo "   iOS Bundle ID: com.example.sampulAppV2"
echo "   Supabase URL: https://rfzblaianldrfwdqdijl.supabase.co"
