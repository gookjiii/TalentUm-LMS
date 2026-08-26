import { VercelRequest, VercelResponse } from '@vercel/node';
import { handleCors } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { id, width } = req.query;

  if (!id || typeof id !== 'string') {
    return res.status(400).json({ error: 'Missing image id' });
  }

  try {
    const parsedWidth = Number.parseInt(String(width ?? ''), 10);
    const previewWidth = Number.isFinite(parsedWidth)
      ? Math.min(Math.max(parsedWidth, 1000), 4096)
      : 1000;

    // We proxy the thumbnail endpoint because it reliably returns images
    // and avoids the "too large to scan for viruses" HTML redirect issue of the uc endpoint.
    const url = `https://drive.google.com/thumbnail?id=${id}&sz=w${previewWidth}`;
    const response = await fetch(url);
    
    if (!response.ok) {
      return res.status(response.status).json({ error: 'Failed to fetch image from Google Drive' });
    }

    const contentType = response.headers.get('content-type') || 'image/jpeg';

    // Never proxy private Drive content through the service account. Uploads
    // intended for the app are finalized with an explicit reader permission.
    if (contentType.includes('text/html')) {
      return res.status(403).json({ error: 'Drive file is not publicly readable' });
    }

    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    
    res.setHeader('Cache-Control', 'public, max-age=86400, s-maxage=86400');
    res.setHeader('Content-Type', contentType);

    return res.send(buffer);
  } catch (error: any) {
    console.error('Error proxying image:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}
