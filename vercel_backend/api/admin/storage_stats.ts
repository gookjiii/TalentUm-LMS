import { VercelRequest, VercelResponse } from '@vercel/node';
import { v2 as cloudinary } from 'cloudinary';
import { getDriveClient, getDriveFolderId } from '../../utils/drive';
import { firebaseAdmin } from '../../utils/firebase';
import { handleCors, requireStaffToken } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const staffToken = await requireStaffToken(req);
  if (!staffToken) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const debug: string[] = [];

  const parseBytes = (value: unknown): number => {
    if (typeof value === 'number' && Number.isFinite(value)) return Math.max(0, Math.round(value));
    if (typeof value !== 'string') return 0;
    const normalized = value.replace(/,/g, '').trim();
    const parsed = Number(normalized);
    return Number.isFinite(parsed) ? Math.max(0, Math.round(parsed)) : 0;
  };

  // Drive's about.storageQuota is the quota of the authenticated principal.
  // Keep the app's configured plan limit separate because a service account or
  // a shared-drive principal may expose a different quota than the storage plan
  // used by TalentUm. GOOGLE_DRIVE_STORAGE_LIMIT_BYTES can override this value.
  const defaultGoogleDriveLimit = 5 * 1024 * 1024 * 1024 * 1024; // 5 TB
  const configuredGoogleDriveLimit = parseBytes(
    process.env.GOOGLE_DRIVE_STORAGE_LIMIT_BYTES,
  );
  const hasConfiguredGoogleDriveLimit = configuredGoogleDriveLimit > 0;

  // For service accounts and shared folders, the folder listing is the source
  // of truth for the files managed by this app even when the account quota is 0.
  const sumDriveFolderBytes = async (driveClient: any, folderId: string): Promise<number> => {
    let total = 0;
    let pageToken: string | undefined;
    do {
      const page = await driveClient.files.list({
        q: `'${folderId}' in parents and trashed = false`,
        fields: 'nextPageToken,files(size)',
        pageSize: 1000,
        pageToken,
        corpora: 'allDrives',
        includeItemsFromAllDrives: true,
        supportsAllDrives: true,
      });
      for (const file of page.data.files || []) total += parseBytes(file.size);
      pageToken = page.data.nextPageToken || undefined;
    } while (pageToken);
    return total;
  };

  // 1. Google Drive storage usage via Drive API
  // The configured TalentUm plan is authoritative when the API is authenticated
  // as a service account or another principal with a different quota.
  let googleDriveLimit = hasConfiguredGoogleDriveLimit
      ? configuredGoogleDriveLimit
      : defaultGoogleDriveLimit;
  let googleDriveUsed = 0;
  let googleDriveError: any = null;
  try {
    const driveClient = await getDriveClient();
    const about = await driveClient.about.get({ fields: 'storageQuota' });
    if (about.data.storageQuota) {
      const apiLimit = parseBytes(about.data.storageQuota.limit);
      if (!hasConfiguredGoogleDriveLimit && apiLimit > defaultGoogleDriveLimit) {
        googleDriveLimit = apiLimit;
      }
      googleDriveUsed =
          parseBytes(about.data.storageQuota.usageInDrive) ||
          parseBytes(about.data.storageQuota.usage);
      debug.push(
          `Drive quota API: used=${googleDriveUsed}, apiLimit=${apiLimit}, ` +
          `limit=${googleDriveLimit}, source=${hasConfiguredGoogleDriveLimit ? 'configured' : 'app-default-or-api'}`,
      );
    }
    try {
      const folderUsed = await sumDriveFolderBytes(driveClient, getDriveFolderId());
      if (folderUsed > googleDriveUsed) googleDriveUsed = folderUsed;
      debug.push(`Drive folder scan: used=${folderUsed} bytes`);
    } catch (folderError: any) {
      debug.push(`Drive folder scan error: ${folderError?.message || folderError}`);
    }
  } catch (error: any) {
    googleDriveError = error.message || String(error);
    debug.push(`Drive API error: ${googleDriveError}`);
  }

  // 2. Cloudinary usage via Cloudinary Admin API
  let cloudinaryLimit = 25 * 1024 * 1024 * 1024;
  let cloudinaryUsed = 0;
  let cloudinaryError: any = null;
  try {
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME || 'dp50nlimq';
    const apiKey = process.env.CLOUDINARY_API_KEY;
    const apiSecret = process.env.CLOUDINARY_API_SECRET;

    if (cloudName && apiKey && apiSecret) {
      cloudinary.config({ cloud_name: cloudName, api_key: apiKey, api_secret: apiSecret });
      const usage = await cloudinary.api.usage();
      debug.push(`Cloudinary raw usage: ${JSON.stringify(usage || {})}`);
      if (usage?.storage?.usage != null) {
        cloudinaryUsed = parseBytes(usage.storage.usage);
      } else if (usage?.storage?.used != null) {
        cloudinaryUsed = parseBytes(usage.storage.used);
      } else if (usage?.storage?.credits_usage != null) {
        cloudinaryUsed = Math.round(Number(usage.storage.credits_usage) * 1024 * 1024 * 1024);
      }
      if (usage?.storage?.limit != null) {
        cloudinaryLimit = parseBytes(usage.storage.limit) || cloudinaryLimit;
      }
    } else {
      cloudinaryError = `Missing env: CLOUD_NAME=${!!cloudName}, API_KEY=${!!apiKey}, API_SECRET=${!!apiSecret}`;
      debug.push(cloudinaryError);
    }
  } catch (error: any) {
    cloudinaryError = error.message || String(error);
    debug.push(`Cloudinary error: ${cloudinaryError}`);
  }

  // 3. Firebase Storage bucket file scan
  let firebaseLimit = 5 * 1024 * 1024 * 1024;
  let firebaseUsed = 0;
  let firebaseError: any = null;
  try {
    const configuredBucket = process.env.FIREBASE_STORAGE_BUCKET?.trim();
    const bucketNames = [
      configuredBucket,
      'school-wolrd.firebasestorage.app',
      'school-wolrd.appspot.com',
    ].filter((name, index, all): name is string => Boolean(name) && all.indexOf(name) === index);
    let scannedBucket = '';
    let lastBucketError: any;
    for (const bucketName of bucketNames) {
      try {
        const bucket = firebaseAdmin.storage().bucket(bucketName);
        const [files] = await bucket.getFiles();
        firebaseUsed = files.reduce((sum, file) => sum + parseBytes(file.metadata.size), 0);
        scannedBucket = bucketName;
        debug.push(`Firebase Storage: ${files.length} files, ${firebaseUsed} bytes in bucket ${bucketName}`);
        break;
      } catch (bucketError: any) {
        lastBucketError = bucketError;
      }
    }
    if (!scannedBucket && lastBucketError) throw lastBucketError;
  } catch (error: any) {
    firebaseError = error.message || String(error);
    debug.push(`Firebase Storage error: ${firebaseError}`);
  }

  // 4. Firestore aggregation across all collections
  try {
    const db = firebaseAdmin.firestore();
    let dbDrive = 0;
    let dbCloudinary = 0;
    let dbFirebase = 0;

    function categorize(url: string, sz: number) {
      if (!sz || sz <= 0) return;
      if (url.includes('cloudinary.com') || url.includes('res.cloudinary.com')) {
        dbCloudinary += sz;
      } else if (url.includes('firebasestorage.googleapis.com') || url.includes('storage.googleapis.com')) {
        dbFirebase += sz;
      } else {
        dbDrive += sz;
      }
    }

    // drive_uploads
    const driveSnap = await db.collection('drive_uploads').get();
    debug.push(`drive_uploads docs: ${driveSnap.size}`);
    driveSnap.forEach((doc) => {
      const d = doc.data();
      const sz = parseBytes(d.size || d.fileSize);
      const url = String(d.webContentLink || d.url || '');
      categorize(url, sz);
    });

    // posts attachments
    const postsSnap = await db.collection('posts').get();
    debug.push(`posts docs: ${postsSnap.size}`);
    postsSnap.forEach((doc) => {
      const d = doc.data();
      const attachments = Array.isArray(d.attachments) ? d.attachments : [];
      attachments.forEach((att: any) => {
        const sz = parseBytes(att.size || att.fileSize);
        const url = String(att.url || att.uri || '');
        categorize(url, sz);
      });
    });

    // Library and webinar documents use these collection names in the app.
    // Older deployments used `library`, so keep that collection as a fallback.
    const libraryCollections = ['library_materials', 'library'];
    for (const collectionName of libraryCollections) {
      const libSnap = await db.collection(collectionName).get();
      debug.push(`${collectionName} docs: ${libSnap.size}`);
      libSnap.forEach((doc) => {
      const d = doc.data();
      const sz = parseBytes(d.fileSize || d.size);
      const url = String(d.fileUrl || d.url || '');
      categorize(url, sz);
      });
    }

    const webinarSnap = await db.collection('webinars').get();
    debug.push(`webinars docs: ${webinarSnap.size}`);
    webinarSnap.forEach((doc) => {
      const d = doc.data();
      const sz = parseBytes(d.fileSize || d.size);
      const url = String(d.videoUrl || d.url || '');
      categorize(url, sz);
    });

    // assignments attachments
    const assignmentsSnap = await db.collection('assignments').get();
    debug.push(`assignments docs: ${assignmentsSnap.size}`);
    assignmentsSnap.forEach((doc) => {
      const d = doc.data();
      const attachments = Array.isArray(d.attachments) ? d.attachments : [];
      attachments.forEach((att: any) => {
        const sz = parseBytes(att.size || att.fileSize);
        const url = String(att.url || att.uri || '');
        categorize(url, sz);
      });
    });

    // submissions attachments
    const submissionsSnap = await db.collection('submissions').get();
    debug.push(`submissions docs: ${submissionsSnap.size}`);
    submissionsSnap.forEach((doc) => {
      const d = doc.data();
      const attachments = Array.isArray(d.attachments) ? d.attachments : [];
      attachments.forEach((att: any) => {
        const sz = parseBytes(att.size || att.fileSize);
        const url = String(att.url || att.uri || '');
        categorize(url, sz);
      });
    });

    // users avatars
    const usersSnap = await db.collection('users').get();
    debug.push(`users docs: ${usersSnap.size}`);
    usersSnap.forEach((doc) => {
      const d = doc.data();
      const avatarUrl = String(d.avatarUrl || d.photoURL || d.avatar || '');
      if (avatarUrl) {
        categorize(avatarUrl, 100 * 1024);
      }
    });

    // room messages
    let totalMessages = 0;
    try {
      const messagesSnapshot = await db.collectionGroup('messages').get();
      totalMessages = messagesSnapshot.size;
      messagesSnapshot.forEach((doc) => {
        const d = doc.data();
        const sz = parseBytes(d.size || d.fileSize || d.metadata?.fileSize);
        const url = String(d.uri || d.source || d.url || '');
        categorize(url, sz);
      });
    } catch (msgGroupErr: any) {
      debug.push(`collectionGroup messages fallback: ${msgGroupErr?.message || msgGroupErr}`);
      const roomsSnap = await db.collection('rooms').limit(50).get();
      await Promise.all(
        roomsSnap.docs.map(async (roomDoc) => {
          try {
            const msgSnap = await db.collection('rooms').doc(roomDoc.id).collection('messages').limit(200).get();
            totalMessages += msgSnap.size;
            msgSnap.forEach((doc) => {
              const d = doc.data();
              const sz = parseBytes(d.size || d.fileSize || d.metadata?.fileSize);
              const url = String(d.uri || d.source || d.url || '');
              categorize(url, sz);
            });
          } catch (_) {}
        })
      );
    }
    debug.push(`Scanned: ${totalMessages} messages, dbDrive=${dbDrive}, dbCloudinary=${dbCloudinary}, dbFirebase=${dbFirebase}`);

    if (googleDriveUsed < dbDrive) googleDriveUsed = dbDrive;
    if (cloudinaryUsed < dbCloudinary) cloudinaryUsed = dbCloudinary;
    if (firebaseUsed < dbFirebase) firebaseUsed = dbFirebase;
  } catch (err: any) {
    debug.push(`Firestore aggregation error: ${err.message || err}`);
  }

  const response = {
    googleDrive: { limit: googleDriveLimit, used: googleDriveUsed, error: googleDriveError },
    cloudinary: { limit: cloudinaryLimit, used: cloudinaryUsed, error: cloudinaryError },
    firebase: { limit: firebaseLimit, used: firebaseUsed, error: firebaseError },
    _debug: debug,
  };
  console.info('Storage stats summary:', JSON.stringify({
    googleDrive: response.googleDrive,
    cloudinary: response.cloudinary,
    firebase: response.firebase,
  }));
  return res.status(200).json(response);
}
