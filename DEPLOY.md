# Deployment Guide

This project consists of a Flutter Web frontend (deployed to Firebase Hosting) and a Node.js backend proxy for Google Drive (deployed to Vercel).

## 1. Backend (Google Drive Proxy)
The backend is located in the `vercel_backend` directory. It handles resumable uploads to Google Drive.

### Steps to Deploy:
1.  **Vercel Account**: Ensure you have a Vercel account and the `vercel` CLI installed (`npm install -g vercel`).
2.  **Navigate to Backend**:
    ```bash
    cd vercel_backend
    ```
3.  **Deploy**:
    ```bash
    vercel --prod
    ```
4.  **Set Environment Variables**:
    In the Vercel Dashboard, set the following variables:
    *   `GOOGLE_SERVICE_ACCOUNT_JSON`: Your full service account JSON string.
    *   `GOOGLE_DRIVE_FOLDER_ID`: The ID of the folder where files will be stored.
    *   `DATABASE_URL`: A PostgreSQL connection string (required for tracking resumable uploads).
    *   *Alternatively*, if using personal OAuth for Google Drive: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REFRESH_TOKEN`.
5.  **Get Proxy URL**: Note your Vercel deployment URL (e.g., `https://your-app.vercel.app`).

## 2. Frontend (Flutter Web)
The frontend requires Cloudinary and the Vercel Proxy URL to be injected at build time.

### Steps to Deploy:
1.  **Firebase Account**: Ensure you are logged into Firebase (`firebase login`).
2.  **Prepare Variables**: You need:
    *   `CLOUDINARY_CLOUD_NAME`
    *   `CLOUDINARY_UPLOAD_PRESET`
    *   `GOOGLE_DRIVE_PROXY_URL` (from Step 1)
3.  **Run Deployment Script**:
    ```bash
    CLOUDINARY_CLOUD_NAME=your_name \
    CLOUDINARY_UPLOAD_PRESET=your_preset \
    GOOGLE_DRIVE_PROXY_URL=https://your-app.vercel.app \
    ./deploy_web.sh
    ```

---

## Technical Details
- **Cloudinary**: Used for fast image and video hosting (Chat, Profile).
- **Google Drive**: Used for large library materials, proxied through Vercel to bypass CORS and handle resumable uploads securely.
