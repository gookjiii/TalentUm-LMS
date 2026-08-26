import { VercelRequest, VercelResponse } from '@vercel/node';
import { dbAdmin } from '../../utils/firebase';
import { handleCors, requireStaffToken } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method Not Allowed' });
  if (!await requireStaffToken(req)) return res.status(403).json({ error: 'Teacher or admin access required' });

  try {
    const snapshot = await dbAdmin.collection('drive_uploads').orderBy('createdAt', 'desc').limit(200).get();
    const files = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .filter((file: any) => file.status === 'active');
    return res.status(200).json(files);
  } catch (error) {
    console.error('Error fetching Drive library list:', error);
    return res.status(500).json({ error: 'Failed to fetch Drive library list' });
  }
}
