import { VercelRequest, VercelResponse } from '@vercel/node';
import { driveClient } from '../../utils/drive';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { driveFileId } = req.body;
  const authHeader = req.headers.authorization;
  
  if (!driveFileId) {
    return res.status(400).json({ error: 'Missing driveFileId' });
  }

  // Basic API Secret check to prevent unauthorized public deletion
  const serverSecret = process.env.APP_API_SECRET;
  if (serverSecret && authHeader !== `Bearer ${serverSecret}`) {
    return res.status(401).json({ error: 'Unauthorized: Invalid API Secret' });
  }

  try {
    // Delete the file from Google Drive
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
