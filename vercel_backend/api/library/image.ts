import { VercelRequest, VercelResponse } from '@vercel/node';
import { getDriveClient } from '../../utils/drive';
import { google } from 'googleapis';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { id } = req.query;

  if (!id || typeof id !== 'string') {
    return res.status(400).json({ error: 'Missing or invalid file ID' });
  }

  try {
    // Attempt 1: Fetch thumbnail directly using public unauthenticated Drive API
    // This works if the file is shared as "Anyone with the link can view"
    const publicUrl = `https://drive.google.com/thumbnail?id=${id}&sz=w800`;
    
    // Check if public url works
    const testResponse = await fetch(publicUrl);
    if (testResponse.ok) {
      const contentType = testResponse.headers.get('content-type');
      if (contentType && contentType.startsWith('image/')) {
        const buffer = await testResponse.arrayBuffer();
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Content-Type', contentType);
        res.setHeader('Cache-Control', 'public, max-age=86400');
        return res.status(200).send(Buffer.from(buffer));
      }
    }

    // Attempt 2: If public URL doesn't return an image (likely returns HTML login page)
    // we use the authenticated Service Account/OAuth
    try {
      console.log(`Thumbnail for ${id} returned HTML (likely private). Falling back to authenticated driveClient...`);
      const driveClient = await getDriveClient();
      const driveRes = await driveClient.files.get(
        { fileId: id, alt: 'media' },
        { responseType: 'stream' }
      );

      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
      res.setHeader('Content-Type', driveRes.headers['content-type'] || 'image/jpeg');
      res.setHeader('Cache-Control', 'public, max-age=86400');
      return new Promise((resolve, reject) => {
        (driveRes.data as any)
          .on('end', () => resolve(res.end()))
          .on('error', (err: any) => reject(err))
          .pipe(res);
      });
    } catch (authError: any) {
      console.error(`Authenticated fetch failed for ${id}:`, authError.message);
      return res.redirect(publicUrl); // Fallback to redirect
    }
  } catch (error: any) {
    console.error('Error proxying image:', error);
    if (error.code === 404 || (error.response && error.response.status === 404)) {
      return res.status(404).json({ error: 'File not found' });
    }
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}
