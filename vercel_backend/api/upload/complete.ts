import { VercelRequest, VercelResponse } from '@vercel/node';
import { driveClient } from '../../utils/drive';
import { Client } from 'pg';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { id, driveFileId } = req.body;

  if (!id || !driveFileId) {
    return res.status(400).json({ error: 'Missing parameters: id, driveFileId' });
  }

  const dbClient = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });
  await dbClient.connect();

  try {
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
      id,
    ]);

    return res.status(200).json({ success: true, file });
  } catch (error: any) {
    console.error('Error completing upload:', error);
    return res.status(500).json({ error: 'Failed to complete upload', details: error.message });
  } finally {
    await dbClient.end();
  }
}
