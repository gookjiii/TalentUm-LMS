#!/bin/bash

# Talentum Web Deployment Script
# This script builds the Flutter Web app with Cloudinary and Google Drive configs
# and deploys it to Firebase Hosting.

# --- CONFIGURATION ---
# You can set these here or pass them as environment variables
# CLOUDINARY_CLOUD_NAME="your_cloud_name"
# CLOUDINARY_UPLOAD_PRESET="your_preset"
# GOOGLE_DRIVE_PROXY_URL="https://your-vercel-proxy.vercel.app"
# APP_API_SECRET="your_secret"

if [ -z "$GOOGLE_DRIVE_PROXY_URL" ]; then
  echo "Error: Missing GOOGLE_DRIVE_PROXY_URL."
  echo "Please set GOOGLE_DRIVE_PROXY_URL."
  echo "Example:"
  echo "  GOOGLE_DRIVE_PROXY_URL=https://your-vercel-proxy.vercel.app ./deploy_web.sh"
  exit 1
fi

echo "🚀 Starting Deployment for Talentum Web..."

# 1. Clean and Get Dependencies
echo "📦 Getting dependencies..."
flutter pub get

# 2. Build Flutter Web
echo "🏗 Building Flutter Web..."
flutter build web --release --source-maps \
  --dart-define=CLOUDINARY_CLOUD_NAME=$CLOUDINARY_CLOUD_NAME \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=$CLOUDINARY_UPLOAD_PRESET \
  --dart-define=GOOGLE_DRIVE_PROXY_URL=$GOOGLE_DRIVE_PROXY_URL \
  --dart-define=APP_API_SECRET=$APP_API_SECRET

# 3. Deploy to Firebase
echo "🔥 Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo "✅ Deployment Complete!"
