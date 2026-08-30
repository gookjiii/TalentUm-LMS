import { VercelRequest, VercelResponse } from '@vercel/node';
import { getDriveClient } from '../../utils/drive';

export const config = {
  api: {
    responseLimit: false,
  },
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Range',
  'Access-Control-Expose-Headers':
    'Content-Length, Content-Range, Accept-Ranges, Content-Type, ETag',
};

export default async function handler(req: VercelRequest, res: VercelResponse) {
  for (const [name, value] of Object.entries(corsHeaders)) {
    res.setHeader(name, value);
  }

  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { fileId } = req.query;
  if (!fileId || typeof fileId !== 'string') {
    return res.status(400).json({ error: 'fileId is required' });
  }

  try {
    // Read the media through the authenticated Drive client. The previous
    // implementation used drive.google.com/uc without credentials, which
    // returned an access/confirmation HTML page for private or legacy files.
    const drive = await getDriveClient();
    const mediaResponse: any = await drive.files.get(
      {
        fileId,
        alt: 'media',
        supportsAllDrives: true,
      },
      {
        responseType: 'stream',
        headers: req.headers.range ? { Range: req.headers.range } : undefined,
      },
    );

    const upstreamHeaders = mediaResponse.headers || {};
    const statusCode = Number(mediaResponse.status) || 200;
    res.status(statusCode);

    // Keep the byte-range headers so SfPdfViewer can seek through large PDFs.
    const forwardedHeaders = [
      'content-type',
      'content-length',
      'content-range',
      'accept-ranges',
      'etag',
      'last-modified',
    ];
    for (const header of forwardedHeaders) {
      const value = upstreamHeaders[header];
      if (value != null) res.setHeader(header, value);
    }

    // Some Drive responses omit content-type on media downloads. This route
    // is exclusively used for PDF preview, so provide a stable MIME type.
    if (!upstreamHeaders['content-type']) {
      res.setHeader('Content-Type', 'application/pdf');
    }

    const stream = mediaResponse.data as NodeJS.ReadableStream;
    stream.on('error', (error) => {
      console.error('Google Drive PDF stream error:', error);
      if (!res.headersSent) {
        res.status(502).json({ error: 'PDF stream failed' });
      } else {
        res.destroy(error as Error);
      }
    });

    req.on('close', () => {
      if (!res.writableEnded && 'destroy' in stream) {
        (stream as NodeJS.ReadableStream & { destroy: () => void }).destroy();
      }
    });

    stream.pipe(res);
  } catch (error: any) {
    const upstreamStatus = Number(error?.response?.status || error?.code);
    const status = upstreamStatus === 404
      ? 404
      : upstreamStatus === 403
        ? 403
        : 502;
    console.error('Google Drive PDF proxy error:', error?.message || error);
    return res.status(status).json({
      error: status === 404
        ? 'PDF file not found'
        : status === 403
          ? 'PDF file is not accessible'
          : 'Failed to load PDF from Google Drive',
    });
  }
}
