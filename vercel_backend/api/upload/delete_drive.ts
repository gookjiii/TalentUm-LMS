import { VercelRequest, VercelResponse } from '@vercel/node';
import { getDriveClient } from '../../utils/drive';
import { dbAdmin } from '../../utils/firebase';
import { handleCors, requireAuthenticatedUser, checkRateLimit } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' });
  if (!checkRateLimit(req, 20, 60_000)) return res.status(429).json({ error: 'Too Many Requests' });

  const user = await requireAuthenticatedUser(req);
  if (!user) return res.status(401).json({ error: 'Authentication required' });

  const { driveFileId } = req.body ?? {};
  if (!driveFileId) return res.status(400).json({ error: 'Missing driveFileId' });

  try {
    const records = await dbAdmin.collection('drive_uploads')
      .where('driveFileId', '==', String(driveFileId)).limit(1).get();
    const record = records.docs[0];
    const canManageAll = user.resolvedRole === 'admin' || user.resolvedRole === 'leadTeacher';
    if (!record) {
      if (!canManageAll) return res.status(404).json({ error: 'Managed Drive file not found' });
    } else if (!canManageAll && record.data().ownerUid !== user.uid) {
      return res.status(403).json({ error: 'Drive file belongs to another user' });
    }

    const drive = await getDriveClient();
    await drive.files.delete({ fileId: String(driveFileId), supportsAllDrives: true });
    if (record) await record.ref.delete();
    return res.status(200).json({ success: true });
  } catch (error: any) {
    if (error?.code === 404) return res.status(404).json({ error: 'Drive file not found' });
    console.error('Error deleting Google Drive file:', error);
    return res.status(502).json({ error: 'Failed to delete Google Drive file' });
  }
}
