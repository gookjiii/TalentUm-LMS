import { VercelRequest, VercelResponse } from '@vercel/node';
import * as https from 'https';

export const config = {
  api: {
    responseLimit: false,
  },
};

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Range');
  res.setHeader('Access-Control-Expose-Headers', 'Content-Length, Content-Range, Accept-Ranges');

  if (req.method === 'OPTIONS') return res.status(200).end();

  const { fileId } = req.query;
  if (!fileId || typeof fileId !== 'string') return res.status(400).json({ error: 'fileId is required' });

  const baseUrl = `https://drive.google.com/uc?export=download&id=${fileId}`;

  try {
    const fetchBypassInfo = (url: string, accumulatedCookies: string[] = [], redirects = 0): Promise<{ finalUrl: string, cookies: string[] }> => {
      return new Promise((resolve, reject) => {
        if (redirects > 5) return reject(new Error('Too many redirects'));

        const headers: any = { 'User-Agent': 'Mozilla/5.0' };
        if (accumulatedCookies.length > 0) headers['Cookie'] = accumulatedCookies.join('; ');

        https.get(url, { headers }, (response) => {
          const newCookies = response.headers['set-cookie']?.map(c => c.split(';')[0]) || [];
          const allCookies = [...accumulatedCookies, ...newCookies];

          if (response.statusCode === 302 || response.statusCode === 303) {
            let nextUrl = response.headers.location!;
            if (!nextUrl.startsWith('http')) nextUrl = 'https://drive.google.com' + nextUrl;
            resolve(fetchBypassInfo(nextUrl, allCookies, redirects + 1));
          } else if (response.statusCode === 200 && response.headers['content-type']?.includes('text/html')) {
            let body = '';
            response.on('data', chunk => body += chunk);
            response.on('end', () => {
              // LOG THE BODY to see what's happening
              console.log("----- HTML BODY START -----");
              console.log(body.substring(0, 500));
              console.log("...");
              console.log(body.substring(body.length - 1000));
              console.log("----- HTML BODY END -----");
              
              // Google Drive now uses form action with uuid, or downloadBtn.
              // Let's try to extract download=... or confirm=... or anything that looks like a direct link
              const confirmMatch = body.match(/confirm=([a-zA-Z0-9_-]+)/);
              const hrefMatch = body.match(/href="(\/uc\?export=download[^"]+)"/);
              const actionMatch = body.match(/action="([^"]+)"/);

              if (confirmMatch) {
                resolve({ finalUrl: `${baseUrl}&confirm=${confirmMatch[1]}`, cookies: allCookies });
              } else if (hrefMatch) {
                let u = hrefMatch[1].replace(/&amp;/g, '&');
                resolve({ finalUrl: `https://drive.google.com${u}`, cookies: allCookies });
              } else if (actionMatch && actionMatch[1].includes('export=download')) {
                let u = actionMatch[1].replace(/&amp;/g, '&');
                const parsedUrl = u.startsWith('http') ? u : `https://drive.google.com${u}`;
                resolve({ finalUrl: parsedUrl, cookies: allCookies });
              } else {
                reject(new Error('HTML page found but no direct download link found'));
              }
            });
          } else if (response.statusCode === 200) {
             resolve({ finalUrl: url, cookies: allCookies });
          } else {
             reject(new Error(`Unexpected status ${response.statusCode}`));
          }
        }).on('error', reject);
      });
    };

    const { finalUrl, cookies } = await fetchBypassInfo(baseUrl);

    const headers: any = { 'User-Agent': 'Mozilla/5.0' };
    if (cookies.length > 0) headers['Cookie'] = cookies.join('; ');
    if (req.headers.range) headers['Range'] = req.headers.range;

    const proxyRequest = https.get(finalUrl, { headers }, (proxyRes) => {
      res.status(proxyRes.statusCode || 200);
      const headersToForward = ['content-type', 'content-length', 'content-range', 'accept-ranges', 'content-disposition'];
      for (const header of headersToForward) if (proxyRes.headers[header]) res.setHeader(header, proxyRes.headers[header] as string);
      proxyRes.pipe(res);
    });

    proxyRequest.on('error', (err) => {
      console.error('Proxy stream error:', err);
      if (!res.headersSent) res.status(500).json({ error: 'Stream failed' });
    });

    req.on('close', () => proxyRequest.destroy());

  } catch (error: any) {
    console.error('Proxy error:', error.message);
    res.status(500).json({ error: error.message });
  }
}
