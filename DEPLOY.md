# Deployment Guide

The canonical app is the Flutter project at the repository root. Web is deployed to Firebase Hosting; Firestore/Realtime Database, Firebase Storage and Firebase Auth are the active backend services. `vercel_backend` is the Google Drive large-file proxy.

## 1. Google Drive backend (Vercel)
The backend is located in `vercel_backend`. It creates Google Drive resumable sessions, validates Firebase staff tokens, stores upload metadata in Firestore, and finalizes/deletes Drive files.

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
    *   `FIREBASE_SERVICE_ACCOUNT_JSON`: Service account for Firebase Admin/Firestore.
    *   `GOOGLE_DRIVE_FOLDER_ID`: Target Drive folder or shared-drive folder.
    *   `GOOGLE_DRIVE_PUBLIC_READ`: Set to `false` only if clients will use an authenticated download proxy; defaults to public reader links.
    *   `MAX_DRIVE_UPLOAD_BYTES`: Optional safety limit; defaults to 5 GiB.
    *   *Alternatively*, if using personal OAuth for Google Drive: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REFRESH_TOKEN`.
5.  **Get Proxy URL**: Note your Vercel deployment URL (e.g., `https://your-app.vercel.app`).

## 2. Frontend (Flutter Web)
The frontend sends files at or above the configured threshold to Google Drive through the Vercel proxy. This includes library, homework, assignment, webinar and chat attachments. Firebase Storage or Cloudinary remain available as provider-specific fallbacks for smaller files and transient Drive failures.

### Steps to Deploy:
1.  **Firebase Account**: Ensure you are logged into Firebase (`firebase login`).
2.  **Prepare Variables**: You need:
    *   `CLOUDINARY_CLOUD_NAME`
    *   `CLOUDINARY_UPLOAD_PRESET`
    *   `GOOGLE_DRIVE_PROXY_URL` (Vercel backend URL; required for large-file Drive uploads)
    *   `GOOGLE_DRIVE_LARGE_FILE_THRESHOLD_MB` (optional, default `0`; set a positive value such as `25` to keep smaller files on the standard provider)
3.  **Run Deployment Script**:
    ```bash
    CLOUDINARY_CLOUD_NAME=your_name \
    CLOUDINARY_UPLOAD_PRESET=your_preset \
    GOOGLE_DRIVE_PROXY_URL=https://vercel-talentum-backend.vercel.app \
    GOOGLE_DRIVE_LARGE_FILE_THRESHOLD_MB=25 \
    ./deploy_web.sh
    ```

---

## Technical Details
- **Cloudinary**: Used for fast image and video hosting (Chat, Profile) when an attachment is below the Drive threshold.
- **Firebase Storage**: Fallback storage when Google Drive is unavailable, plus any provider-specific small-file flows.
- **Google Drive/Vercel**: Storage for files at or above the large-file threshold. Firestore tracks upload ownership and metadata; PostgreSQL is not required.
