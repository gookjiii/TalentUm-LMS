import * as admin from 'firebase-admin';

const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON || process.env.GOOGLE_SERVICE_ACCOUNT_JSON;

if (!admin.apps.length) {
  if (serviceAccountJson) {
    try {
      const credentials = JSON.parse(serviceAccountJson);
      if (credentials.private_key) {
        credentials.private_key = credentials.private_key.replace(/\\n/g, '\n');
      }
      admin.initializeApp({
        credential: admin.credential.cert(credentials),
      });
      console.log('Firebase Admin initialized with service account.');
    } catch (e: any) {
      console.error('Failed to initialize Firebase Admin with service account JSON, falling back to default:', e);
      admin.initializeApp();
    }
  } else {
    console.log('Firebase Admin initialized with default credentials.');
    admin.initializeApp();
  }
}

export const firebaseAdmin = admin;
export const authAdmin = admin.auth();
export const dbAdmin = admin.firestore();
