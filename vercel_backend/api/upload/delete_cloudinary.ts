import { VercelRequest, VercelResponse } from '@vercel/node';
import { v2 as cloudinary } from 'cloudinary';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { publicId, resourceType } = req.body;
  const authHeader = req.headers.authorization;
  
  if (!publicId) {
    return res.status(400).json({ error: 'Missing publicId' });
  }

  // Basic API Secret check to prevent unauthorized public deletion
  const serverSecret = process.env.APP_API_SECRET;
  if (serverSecret && authHeader !== `Bearer ${serverSecret}`) {
    return res.status(401).json({ error: 'Unauthorized: Invalid API Secret' });
  }

  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;

  if (!cloudName || !apiKey || !apiSecret) {
    return res.status(500).json({ error: 'Cloudinary credentials are not fully configured on the server.' });
  }

  cloudinary.config({
    cloud_name: cloudName,
    api_key: apiKey,
    api_secret: apiSecret,
  });

  try {
    const result = await cloudinary.uploader.destroy(publicId, {
      resource_type: resourceType || 'image',
    });
    
    return res.status(200).json({ success: true, result });
  } catch (error: any) {
    console.error('Error deleting Cloudinary file:', error);
    return res.status(500).json({ error: 'Failed to delete file', details: error.message });
  }
}
