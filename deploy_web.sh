#!/bin/bash

# Talentum Web Deployment Script
# This script builds the Flutter Web app and deploys it to Firebase Hosting.
# Library, homework, assignment, webinar and large chat attachments use Google
# Drive through the Vercel proxy; Firebase/Cloudinary remain error fallbacks.

# --- CONFIGURATION ---
# You can set these here or pass them as environment variables
# CLOUDINARY_CLOUD_NAME="your_cloud_name"
# CLOUDINARY_UPLOAD_PRESET="your_preset"
# GOOGLE_DRIVE_PROXY_URL="https://vercel-talentum-backend.vercel.app"
# GOOGLE_DRIVE_LARGE_FILE_THRESHOLD_MB="25"

CLOUDINARY_CLOUD_NAME="${CLOUDINARY_CLOUD_NAME:-dp50nlimq}"
CLOUDINARY_UPLOAD_PRESET="${CLOUDINARY_UPLOAD_PRESET:-schoolWorld}"
GOOGLE_DRIVE_PROXY_URL="${GOOGLE_DRIVE_PROXY_URL:-https://vercel-talentum-backend.vercel.app}"
GOOGLE_DRIVE_LARGE_FILE_THRESHOLD_MB="${GOOGLE_DRIVE_LARGE_FILE_THRESHOLD_MB:-0}"

echo "🚀 Starting Deployment for Talentum Web..."

# 1. Clean and Get Dependencies
echo "📦 Getting dependencies..."
flutter pub get

# 2. Build Flutter Web
echo "🏗 Building Flutter Web (CanvasKit)..."
BUILD_ARGS=(flutter build web --release \
  --dart-define=CLOUDINARY_CLOUD_NAME=$CLOUDINARY_CLOUD_NAME \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=$CLOUDINARY_UPLOAD_PRESET \
  --dart-define=GOOGLE_DRIVE_PROXY_URL=$GOOGLE_DRIVE_PROXY_URL \
  --dart-define=GOOGLE_DRIVE_LARGE_FILE_THRESHOLD_MB=$GOOGLE_DRIVE_LARGE_FILE_THRESHOLD_MB)

"${BUILD_ARGS[@]}"

# 3. Deploy to Firebase
echo "🔥 Deploying to Firebase Hosting, Firestore Rules & Storage Rules..."
firebase deploy --only hosting,firestore:rules,storage

echo "✅ Deployment Complete!"
