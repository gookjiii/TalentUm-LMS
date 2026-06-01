import { VercelRequest, VercelResponse } from '@vercel/node';
import { auth, SHARED_FOLDER_ID } from '../../utils/drive';
import { Client } from 'pg';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { name, mimeType, size } = req.body;

  if (!name || !mimeType || !size) {
    return res.status(400).json({ error: 'Missing required parameters: name, mimeType, size' });
  }

  const dbClient = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });
  await dbClient.connect();

  try {
    const tokenResponse = await auth.getAccessToken();
    const accessToken = tokenResponse.token;

    if (!accessToken) {
      throw new Error('Failed to obtain Google Drive Access Token');
    }

    const originHeader = req.headers.origin;
    const requestHeaders: Record<string, string> = {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      'X-Upload-Content-Type': mimeType,
      'X-Upload-Content-Length': size.toString(),
    };

    if (originHeader) {
      requestHeaders['Origin'] = originHeader as string;
    }

    const initiateUrl = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable&supportsAllDrives=true';
    
    const response = await fetch(initiateUrl, {
      method: 'POST',
      headers: requestHeaders,
      body: JSON.stringify({
        name: name,
        parents: [SHARED_FOLDER_ID],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Google API error: ${response.status} - ${errorText}`);
    }

    const uploadUrl = response.headers.get('Location');
    if (!uploadUrl) {
      throw new Error('Failed to retrieve the direct resumable upload URL (Location header empty)');
    }

    const insertQuery = `
      INSERT INTO library_files (name, mime_type, size, status)
      VALUES ($1, $2, $3, 'pending')
      RETURNING id
    `;
    const dbRes = await dbClient.query(insertQuery, [name, mimeType, size]);
    const fileRecordId = dbRes.rows[0].id;

    return res.status(200).json({
      id: fileRecordId,
      uploadUrl: uploadUrl,
    });
  } catch (error: any) {
    console.error('Error initiating upload:', error);
    return res.status(500).json({ error: 'Failed to initiate upload', details: error.message });
  } finally {
    await dbClient.end();
  }
}
