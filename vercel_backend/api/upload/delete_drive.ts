import { VercelRequest, VercelResponse } from '@vercel/node';
import { getDriveClient } from '../../utils/drive';
import { handleCors, requireApiSecret } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== 'POST' && req.method !== 'DELETE') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { driveFileId } = req.body;

  if (!driveFileId) {
    return res.status(400).json({ error: 'Missing driveFileId' });
  }

  if (!requireApiSecret(req)) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    // Delete the file from Google Drive
    const driveClient = await getDriveClient();
    await driveClient.files.delete({
      fileId: driveFileId,
      supportsAllDrives: true,
    });

    // Note: We don't delete from PostgreSQL library_files here because that table
    // is only tracking upload status.
    return res.status(200).json({ success: true });
  } catch (error: any) {
    console.error('Error deleting Google Drive file:', error);
    return res.status(500).json({ error: 'Failed to delete file', details: error.message });
  }
}
