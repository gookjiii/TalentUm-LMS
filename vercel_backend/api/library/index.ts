import { VercelRequest, VercelResponse } from '@vercel/node';
import { Client } from 'pg';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const dbClient = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });
  await dbClient.connect();

  try {
    const query = 'SELECT id, name, mime_type, web_view_link, thumbnail_link, size, created_at FROM library_files ORDER BY created_at DESC';
    const dbRes = await dbClient.query(query);

    return res.status(200).json(dbRes.rows);
  } catch (error: any) {
    console.error('Error fetching library list:', error);
    return res.status(500).json({ error: 'Internal Server Error', details: error.message });
  } finally {
    await dbClient.end();
  }
}
