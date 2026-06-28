import { VercelRequest, VercelResponse } from '@vercel/node';
import { getDriveClient } from '../../utils/drive';
import { Client } from 'pg';
import { handleCors, verifyFirebaseToken, checkRateLimit } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  if (!checkRateLimit(req, 20, 60000)) {
    return res.status(429).json({ error: 'Too Many Requests' });
  }

  const authUser = await verifyFirebaseToken(req);
  if (!authUser) {
    return res.status(401).json({ error: 'Unauthorized: Invalid or missing Firebase ID token' });
  }

  const { id, driveFileId } = req.body;

  if (typeof id !== 'string' && typeof id !== 'number') {
    return res.status(400).json({ error: 'Invalid parameter: id' });
  }

  if (typeof driveFileId !== 'string' || driveFileId.trim().length === 0) {
    return res.status(400).json({ error: 'Missing parameters: id, driveFileId' });
  }

  const dbClient = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 3000
  });

  try {
    await dbClient.connect();
  } catch (dbError: any) {
    console.error('Database connection failed:', dbError);
    return res.status(500).json({
      error: 'Database connection failed. Is the database paused?',
      details: dbError.message
    });
  }

  try {
    const driveClient = await getDriveClient();
    const driveRes = await driveClient.files.get({
      fileId: driveFileId,
      fields: 'id, name, mimeType, webViewLink, webContentLink, thumbnailLink',
      supportsAllDrives: true,
    });

    const file = driveRes.data;

    const updateQuery = `
      UPDATE library_files
      SET drive_file_id = $1,
          web_view_link = $2,
          web_content_link = $3,
          thumbnail_link = $4,
          status = 'active'
      WHERE id = $5
    `;
    await dbClient.query(updateQuery, [
      file.id,
      file.webViewLink,
      file.webContentLink,
      file.thumbnailLink,
      id.toString(),
    ]);

    return res.status(200).json({ success: true, file });
  } catch (error: any) {
    console.error('Error completing upload:', error);
    return res.status(500).json({ error: 'Failed to complete upload', details: error.message });
  } finally {
    await dbClient.end();
  }
}
