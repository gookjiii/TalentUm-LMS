import { VercelRequest, VercelResponse } from '@vercel/node';
import { driveClient } from '../../utils/drive';

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
    return res.status(400).json({ error: 'Missing image id' });
  }

  try {
    // We proxy the thumbnail endpoint because it reliably returns images
    // and avoids the "too large to scan for viruses" HTML redirect issue of the uc endpoint.
    const url = `https://drive.google.com/thumbnail?id=${id}&sz=w1000`;
    const response = await fetch(url);
    
    if (!response.ok) {
      return res.status(response.status).json({ error: 'Failed to fetch image from Google Drive' });
    }

    const contentType = response.headers.get('content-type') || 'image/jpeg';

    // If the file is private, Google Drive redirects to a login page, returning an HTML document.
    // Instead of crashing the Flutter app with an ImageCodecException, we fallback to the authenticated Drive client.
    if (contentType.includes('text/html')) {
      console.log(`Thumbnail for ${id} returned HTML (likely private). Falling back to authenticated driveClient...`);
      const driveRes = await driveClient.files.get(
        { fileId: id, alt: 'media' },
        { responseType: 'stream' }
      );

      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
      res.setHeader('Cache-Control', 'public, max-age=86400, s-maxage=86400');
      res.setHeader('Content-Type', (driveRes.headers['content-type'] as string) || 'image/jpeg');

      return new Promise((resolve, reject) => {
        (driveRes.data as any)
          .on('end', () => resolve(res.end()))
          .on('error', (err: any) => reject(err))
          .pipe(res);
      });
    }

    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Cache-Control', 'public, max-age=86400, s-maxage=86400');
    res.setHeader('Content-Type', contentType);

    return res.send(buffer);
  } catch (error: any) {
    console.error('Error proxying image:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}
