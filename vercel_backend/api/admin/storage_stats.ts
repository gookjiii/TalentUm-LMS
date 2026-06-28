import { VercelRequest, VercelResponse } from '@vercel/node';
import { v2 as cloudinary } from 'cloudinary';
import { getDriveClient } from '../../utils/drive';
import { firebaseAdmin } from '../../utils/firebase';
import { handleCors, requireApiSecret } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  if (!requireApiSecret(req)) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // 1. Fetch Google Drive storage stats
  let googleDriveLimit = 15 * 1024 * 1024 * 1024; // Default 15 GB free tier
  let googleDriveUsed = 0;
  try {
    const driveClient = await getDriveClient();
    const about = await driveClient.about.get({
      fields: 'storageQuota',
    });
    if (about.data.storageQuota) {
      googleDriveLimit = parseInt(about.data.storageQuota.limit || '0') || googleDriveLimit;
      googleDriveUsed = parseInt(about.data.storageQuota.usage || '0');
    }
  } catch (error: any) {
    console.error('Error fetching Google Drive storage stats:', error);
  }

  // 2. Fetch Cloudinary storage stats
  let cloudinaryLimit = 25 * 1024 * 1024 * 1024; // Default 25 GB free tier
  let cloudinaryUsed = 0;
  let cloudinaryError: any = null;
  try {
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const apiKey = process.env.CLOUDINARY_API_KEY;
    const apiSecret = process.env.CLOUDINARY_API_SECRET;

    if (cloudName && apiKey && apiSecret) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
      });
      const usage = await cloudinary.api.usage();
      if (usage && usage.storage) {
        cloudinaryLimit = usage.storage.limit || cloudinaryLimit;
        cloudinaryUsed = usage.storage.usage || 0;
      }
    } else {
      cloudinaryError = `Missing env: cloudName=${!!cloudName}, apiKey=${!!apiKey}, apiSecret=${!!apiSecret}`;
    }
  } catch (error: any) {
    console.error('Error fetching Cloudinary storage stats:', error);
    cloudinaryError = error.message || String(error);
  }

  // 3. Fetch Firebase Storage stats (aggregate file sizes)
  let firebaseLimit = 5 * 1024 * 1024 * 1024; // Default 5 GB free tier
  let firebaseUsed = 0;
  let firebaseError: any = null;
  try {
    const bucketName = process.env.FIREBASE_STORAGE_BUCKET || 'school-wolrd.firebasestorage.app';
    const bucket = firebaseAdmin.storage().bucket(bucketName);
    const [files] = await bucket.getFiles();
    for (const file of files) {
      firebaseUsed += parseInt(String(file.metadata.size || '0'), 10);
    }
  } catch (error: any) {
    console.error('Error fetching Firebase Storage stats:', error);
    firebaseError = error.message || String(error);
  }

  return res.status(200).json({
    googleDrive: {
      limit: googleDriveLimit,
      used: googleDriveUsed,
    },
    cloudinary: {
      limit: cloudinaryLimit,
      used: cloudinaryUsed,
      error: cloudinaryError,
    },
    firebase: {
      limit: firebaseLimit,
      used: firebaseUsed,
      error: firebaseError,
    },
  });
}
