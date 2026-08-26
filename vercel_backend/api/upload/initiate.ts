import { VercelRequest, VercelResponse } from '@vercel/node';
import { getDriveAccessToken, getDriveFolderId } from '../../utils/drive';
import { dbAdmin, firebaseAdmin } from '../../utils/firebase';
import { handleCors, requireAuthenticatedUser, checkRateLimit } from '../../utils/api';

const DEFAULT_MAX_UPLOAD_BYTES = 5 * 1024 * 1024 * 1024;

export const config = {
  api: {
    bodyParser: false,
  },
};

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  // Handle PUT: Proxy chunk to Google Drive
  if (req.method === 'PUT') {
    const user = await requireAuthenticatedUser(req);
    if (!user) return res.status(401).json({ error: 'Authentication required' });

    const uploadUrl = (req.headers['x-upload-url'] || '') as string;
    const contentRange = (req.headers['x-upload-content-range'] || req.headers['content-range'] || '') as string;
    const contentType = (req.headers['content-type'] || 'application/octet-stream') as string;

    if (!uploadUrl) return res.status(400).json({ error: 'Missing x-upload-url header' });

    try {
      const buffers: Buffer[] = [];
      for await (const chunk of req) {
        buffers.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
      }
      const bodyBuffer = Buffer.concat(buffers);

      const response = await fetch(uploadUrl, {
        method: 'PUT',
        headers: {
          'Content-Type': contentType,
          'Content-Range': contentRange,
        },
        body: bodyBuffer,
      });

      res.status(response.status);
      const rangeHeader = response.headers.get('range');
      if (rangeHeader) res.setHeader('Range', rangeHeader);
      const contentTypeHeader = response.headers.get('content-type');
      if (contentTypeHeader) res.setHeader('Content-Type', contentTypeHeader);

      const responseText = await response.text();
      return res.send(responseText);
    } catch (error: any) {
      console.error('Error proxying chunk in initiate handler:', error);
      return res.status(502).json({ error: 'Failed to proxy chunk to Google Drive' });
    }
  }

  // Handle POST: Initiate upload session
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' });
  if (!checkRateLimit(req, 20, 60_000)) return res.status(429).json({ error: 'Too Many Requests' });

  const user = await requireAuthenticatedUser(req);
  if (!user) return res.status(401).json({ error: 'Authentication required' });

  // Parse JSON body manually when bodyParser is false
  let bodyJson: any = {};
  try {
    const buffers: Buffer[] = [];
    for await (const chunk of req) {
      buffers.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    }
    const raw = Buffer.concat(buffers).toString('utf8');
    bodyJson = raw ? JSON.parse(raw) : {};
  } catch (e) {
    return res.status(400).json({ error: 'Invalid JSON body' });
  }

  const { name, mimeType, size, path } = bodyJson ?? {};
  const parsedSize = Number(size);
  const maxUploadBytes = Number(process.env.MAX_DRIVE_UPLOAD_BYTES || DEFAULT_MAX_UPLOAD_BYTES);
  const safeName = String(name || '').split(/[\\/]/).pop()?.trim() || '';
  const safeMimeType = String(mimeType || '').trim();

  if (!safeName || safeName.length > 255 || !safeMimeType || !Number.isSafeInteger(parsedSize) || parsedSize <= 0) {
    return res.status(400).json({ error: 'Invalid name, mimeType, or size' });
  }
  if (parsedSize > maxUploadBytes) {
    return res.status(413).json({ error: 'File exceeds the configured Google Drive upload limit' });
  }

  try {
    const accessToken = await getDriveAccessToken();
    const folderId = getDriveFolderId();
    const response = await fetch(
      'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable&supportsAllDrives=true',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Upload-Content-Type': safeMimeType,
          'X-Upload-Content-Length': parsedSize.toString(),
        },
        body: JSON.stringify({ name: safeName, parents: [folderId] }),
      },
    );

    if (!response.ok) {
      const details = await response.text();
      console.error('Google Drive session initiation failed:', response.status, details);
      return res.status(502).json({ error: 'Google Drive rejected the upload session' });
    }

    const uploadUrl = response.headers.get('location');
    if (!uploadUrl) return res.status(502).json({ error: 'Google Drive did not return an upload URL' });

    const record = dbAdmin.collection('drive_uploads').doc();
    await record.set({
      ownerUid: user.uid,
      ownerRole: user.resolvedRole,
      name: safeName,
      mimeType: safeMimeType,
      size: parsedSize,
      path: typeof path === 'string' ? path.slice(0, 1024) : null,
      folderId,
      status: 'pending',
      createdAt: firebaseAdmin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json({ id: record.id, uploadUrl });
  } catch (error: any) {
    console.error('Error initiating Google Drive upload:', error);
    return res.status(503).json({ error: 'Google Drive upload service is unavailable' });
  }
}
