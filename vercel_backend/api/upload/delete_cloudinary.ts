import { VercelRequest, VercelResponse } from '@vercel/node';
import { v2 as cloudinary } from 'cloudinary';
import { handleCors, verifyFirebaseToken } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { publicId, resourceType } = req.body;
  if (!publicId) {
    return res.status(400).json({ error: 'Missing publicId' });
  }

  if (!await verifyFirebaseToken(req)) {
    return res.status(401).json({ error: 'Unauthorized: Invalid or missing Firebase ID token' });
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
