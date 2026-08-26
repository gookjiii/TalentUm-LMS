import { VercelRequest, VercelResponse } from '@vercel/node';
import { v2 as cloudinary } from 'cloudinary';
import { getDriveClient } from '../../utils/drive';
import { firebaseAdmin, dbAdmin } from '../../utils/firebase';
import { handleCors, requireAdminToken } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  if (!await requireAdminToken(req)) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const dryRun = req.body.dryRun === true;

  try {
    // 1. Fetch all active file references from Firestore
    const activeRefs = new Set<string>();

    // 1a. Messages (all chat rooms)
    const messagesSnapshot = await dbAdmin.collectionGroup('messages').get();
    messagesSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.source) activeRefs.add(data.source.toString());
      if (data.uri) activeRefs.add(data.uri.toString());
      if (data.url) activeRefs.add(data.url.toString());
      if (data.metadata?.fileUrl) activeRefs.add(data.metadata.fileUrl.toString());
      const text = data.metadata?.text || data.text;
      if (text) activeRefs.add(text.toString());
    });

    // 1b. Library Materials and legacy library collection
    for (const col of ['library_materials', 'library']) {
      try {
        const librarySnapshot = await dbAdmin.collection(col).get();
        librarySnapshot.forEach((doc) => {
          const data = doc.data();
          if (data.fileUrl) activeRefs.add(data.fileUrl.toString());
          if (data.url) activeRefs.add(data.url.toString());
        });
      } catch (_) {}
    }

    // 1c. Drive uploads
    const driveUploadsSnapshot = await dbAdmin.collection('drive_uploads').get();
    driveUploadsSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.status === 'active' && data.driveFileId) {
        activeRefs.add(data.driveFileId.toString());
      }
      if (data.webViewLink) activeRefs.add(data.webViewLink.toString());
      if (data.webContentLink) activeRefs.add(data.webContentLink.toString());
      if (data.url) activeRefs.add(data.url.toString());
    });

    // 1d. Posts (school feed)
    const postsSnapshot = await dbAdmin.collection('posts').get();
    postsSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.url) activeRefs.add(data.url.toString());
      const attachments = Array.isArray(data.attachments) ? data.attachments : [];
      attachments.forEach((att: any) => {
        if (att?.url) activeRefs.add(att.url.toString());
        if (att?.uri) activeRefs.add(att.uri.toString());
      });
    });

    // 1e. Assignments (teacher homework)
    const assignmentsSnapshot = await dbAdmin.collection('assignments').get();
    assignmentsSnapshot.forEach((doc) => {
      const data = doc.data();
      const attachments = Array.isArray(data.attachments) ? data.attachments : [];
      attachments.forEach((att: any) => {
        if (att?.url) activeRefs.add(att.url.toString());
        if (att?.uri) activeRefs.add(att.uri.toString());
      });
    });

    // 1f. Submissions (student homework submissions)
    const submissionsSnapshot = await dbAdmin.collection('submissions').get();
    submissionsSnapshot.forEach((doc) => {
      const data = doc.data();
      const attachments = Array.isArray(data.attachments) ? data.attachments : [];
      attachments.forEach((att: any) => {
        if (att?.url) activeRefs.add(att.url.toString());
        if (att?.uri) activeRefs.add(att.uri.toString());
      });
    });

    // 1g. Webinars
    const webinarsSnapshot = await dbAdmin.collection('webinars').get();
    webinarsSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.videoUrl) activeRefs.add(data.videoUrl.toString());
      if (data.url) activeRefs.add(data.url.toString());
    });

    // 1h. Users avatars
    const usersSnapshot = await dbAdmin.collection('users').get();
    usersSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.avatarUrl) activeRefs.add(data.avatarUrl.toString());
      if (data.photoURL) activeRefs.add(data.photoURL.toString());
      if (data.avatar) activeRefs.add(data.avatar.toString());
    });

    // 1i. Classes avatars
    const classesSnapshot = await dbAdmin.collection('classes').get();
    classesSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.avatarUrl) activeRefs.add(data.avatarUrl.toString());
      if (data.avatar) activeRefs.add(data.avatar.toString());
    });

    // 1j. System Branding & settings
    for (const [col, docId] of [['system_settings', 'branding'], ['settings', 'system']]) {
      try {
        const sysDoc = await dbAdmin.collection(col).doc(docId).get();
        if (sysDoc.exists) {
          const d = sysDoc.data();
          if (d?.logoUrl) activeRefs.add(d.logoUrl.toString());
          if (d?.logo) activeRefs.add(d.logo.toString());
        }
      } catch (_) {}
    }

    // 2. Firebase Storage Cleanup
    let firebaseDeletedCount = 0;
    let firebaseDeletedBytes = 0;
    try {
      const bucketName = process.env.FIREBASE_STORAGE_BUCKET || 'school-wolrd.firebasestorage.app';
      const bucket = firebaseAdmin.storage().bucket(bucketName);
      const [files] = await bucket.getFiles();
      
      for (const file of files) {
        const fileName = file.name;
        // Skip system folders
        if (fileName.startsWith('system/logo_') || fileName === 'system/logo') {
          continue;
        }

        const isReferenced = Array.from(activeRefs).some((ref) => ref.includes(fileName));
        if (!isReferenced) {
          const size = parseInt(String(file.metadata.size || '0'), 10);
          if (!dryRun) {
            await file.delete();
          }
          firebaseDeletedCount++;
          firebaseDeletedBytes += size;
        }
      }
    } catch (e) {
      console.error('Firebase Storage cleanup error:', e);
    }

    // 3. Cloudinary Cleanup
    let cloudinaryDeletedCount = 0;
    let cloudinaryDeletedBytes = 0;
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

        const resources = await cloudinary.api.resources({
          type: 'upload',
          max_results: 500,
        });

        const publicIdsToDelete: string[] = [];
        for (const asset of resources.resources) {
          const secureUrl = asset.secure_url;
          const url = asset.url;
          const publicId = asset.public_id;

          if (publicId.startsWith('system/logo')) {
            continue;
          }

          const isReferenced = Array.from(activeRefs).some(
            (ref) => ref.includes(publicId) || ref === secureUrl || ref === url
          );
          
          if (!isReferenced) {
            publicIdsToDelete.push(publicId);
            cloudinaryDeletedBytes += asset.bytes || 0;
          }
        }

        if (publicIdsToDelete.length > 0) {
          if (!dryRun) {
            await cloudinary.api.delete_resources(publicIdsToDelete);
          }
          cloudinaryDeletedCount = publicIdsToDelete.length;
        }
      }
    } catch (e) {
      console.error('Cloudinary cleanup error:', e);
    }

    // 4. Google Drive Cleanup
    let googleDriveDeletedCount = 0;
    let googleDriveDeletedBytes = 0;
    try {
      const driveFolderId = process.env.GOOGLE_DRIVE_FOLDER_ID;
      if (driveFolderId) {
        const driveClient = await getDriveClient();
        const driveResponse = await driveClient.files.list({
          q: `'${driveFolderId}' in parents and trashed = false`,
          fields: 'files(id, name, size)',
        });

        if (driveResponse.data.files) {
          for (const file of driveResponse.data.files) {
            const fileId = file.id;
            const size = parseInt(file.size || '0');

            if (!fileId) continue;

            const isReferenced = Array.from(activeRefs).some((ref) => ref.includes(fileId));
            if (!isReferenced) {
              if (!dryRun) {
                await driveClient.files.delete({
                  fileId: fileId,
                  supportsAllDrives: true,
                });
              }
              googleDriveDeletedCount++;
              googleDriveDeletedBytes += size;
            }
          }
        }
      }
    } catch (e) {
      console.error('Google Drive cleanup error:', e);
    }

    return res.status(200).json({
      success: true,
      dryRun,
      summary: {
        firebase: {
          deletedCount: firebaseDeletedCount,
          deletedBytes: firebaseDeletedBytes,
        },
        cloudinary: {
          deletedCount: cloudinaryDeletedCount,
          deletedBytes: cloudinaryDeletedBytes,
        },
        googleDrive: {
          deletedCount: googleDriveDeletedCount,
          deletedBytes: googleDriveDeletedBytes,
        },
        totalFilesDeleted: firebaseDeletedCount + cloudinaryDeletedCount + googleDriveDeletedCount,
        totalBytesSaved: firebaseDeletedBytes + cloudinaryDeletedBytes + googleDriveDeletedBytes,
      },
    });
  } catch (error: any) {
    console.error('Error executing storage cleanup:', error);
    return res.status(500).json({ error: 'Storage cleanup failed', details: error.message });
  }
}
