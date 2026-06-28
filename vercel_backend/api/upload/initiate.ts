import { VercelRequest, VercelResponse } from '@vercel/node';
import { getWorkingAuthClient, SHARED_FOLDER_ID } from '../../utils/drive';
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

  const { name, mimeType, size } = req.body;

  if (typeof name !== 'string' || name.trim().length === 0 || name.length > 255) {
    return res.status(400).json({ error: 'Invalid parameter: name must be a non-empty string up to 255 characters' });
  }

  if (typeof mimeType !== 'string' || mimeType.trim().length === 0 || mimeType.length > 150) {
    return res.status(400).json({ error: 'Invalid parameter: mimeType must be a non-empty string' });
  }

  const sizeBytes = typeof size === 'number' ? size : Number(size);
  if (!Number.isFinite(sizeBytes) || sizeBytes <= 0) {
    return res.status(400).json({ error: 'Missing required parameters: name, mimeType, size' });
  }

  const maxUploadBytes = parseInt(process.env.MAX_UPLOAD_BYTES || '104857600', 10); // 100MB default
  if (sizeBytes > maxUploadBytes) {
    return res.status(413).json({ error: `Payload Too Large: File size exceeds the maximum limit of ${maxUploadBytes} bytes` });
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
    const auth = await getWorkingAuthClient();
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
      'X-Upload-Content-Length': sizeBytes.toString(),
    };

    if (originHeader) {
      requestHeaders['Origin'] = originHeader as string;
    }

    const initiateUrl = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable&supportsAllDrives=true';

    const response = await fetch(initiateUrl, {
      method: 'POST',
      headers: requestHeaders,
      body: JSON.stringify({
        name: name.trim(),
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
    const dbRes = await dbClient.query(insertQuery, [name.trim(), mimeType, sizeBytes]);
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
