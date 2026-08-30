import { VercelRequest, VercelResponse } from '@vercel/node';
import { getDriveClient, getDriveFolderId } from '../../utils/drive';
import { dbAdmin, firebaseAdmin } from '../../utils/firebase';
import { handleCors, requireAuthenticatedUser, checkRateLimit } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' });
  if (!checkRateLimit(req, 20, 60_000)) return res.status(429).json({ error: 'Too Many Requests' });

  const user = await requireAuthenticatedUser(req);
  if (!user) return res.status(401).json({ error: 'Authentication required' });

  const { id, driveFileId } = req.body ?? {};
  if (!id || !driveFileId) return res.status(400).json({ error: 'Missing id or driveFileId' });

  try {
    const recordRef = dbAdmin.collection('drive_uploads').doc(String(id));
    const recordSnapshot = await recordRef.get();
    if (!recordSnapshot.exists) return res.status(404).json({ error: 'Upload record not found' });

    const record = recordSnapshot.data()!;
    const canManageAll = user.resolvedRole === 'admin' || user.resolvedRole === 'leadTeacher';
    if (!canManageAll && record.ownerUid !== user.uid) {
      return res.status(403).json({ error: 'Upload record belongs to another user' });
    }
    if (record.status !== 'pending') return res.status(409).json({ error: 'Upload is not pending' });

    const drive = await getDriveClient();
    const folderId = getDriveFolderId();
    const driveRes = await drive.files.get({
      fileId: String(driveFileId),
      fields: 'id,name,mimeType,size,parents,webViewLink,webContentLink,thumbnailLink',
      supportsAllDrives: true,
    });
    const file = driveRes.data;

    if (!file.parents?.includes(folderId)) return res.status(403).json({ error: 'File is outside the configured folder' });

    if (process.env.GOOGLE_DRIVE_PUBLIC_READ !== 'false') {
      try {
        await drive.permissions.create({
          fileId: String(driveFileId),
          supportsAllDrives: true,
          requestBody: { type: 'anyone', role: 'reader' },
        });
      } catch (permErr: any) {
        console.warn('Failed to set public read permission:', permErr?.message || permErr);
      }
    }

    if (!file.id) {
      return res.status(502).json({ error: 'Google Drive returned no file ID' });
    }

    const updateData: Record<string, unknown> = {
      driveFileId: file.id,
      status: 'active',
      completedAt: firebaseAdmin.firestore.FieldValue.serverTimestamp(),
    };
    if (file.webViewLink) updateData.webViewLink = file.webViewLink;
    if (file.webContentLink) updateData.webContentLink = file.webContentLink;
    if (file.thumbnailLink) updateData.thumbnailLink = file.thumbnailLink;

    await recordRef.update(updateData);

    return res.status(200).json({ success: true, file });
  } catch (error: any) {
    console.error('Error completing Google Drive upload:', error);
    return res.status(502).json({ error: 'Failed to finalize Google Drive upload' });
  }
}
